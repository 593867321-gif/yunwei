# Codemagic 构建 iOS 正式版（IPA）操作指引

> 适用版本：优达客运营 1.0.5 (build 7)　生成：2026-09-11
> 目标：在 Codemagic 的 macOS 构建机上，产出**可安装到真机**的签名 IPA。

---

## 零、先读：分工与安全红线

**我（已在本地替你做完）：**
- 组装好这个自包含 CI 包：项目源码 + 功能替代库（`local_deps/`）+ 改好 path 依赖的 `pubspec.yaml` + `codemagic.yaml` + `.gitignore` + 本指引
- 本地验证过：`pub get` / `build_runner` / `gen-l10n` / `analyze` 全部通过（0 error）
- iOS 工程的 `push_config.plist` 致命阻断已修复（删了 4 处无效引用，解析器验证工程完整）

**你（只能用你的账号凭据做，我无法代劳）：**
- 注册 Codemagic、准备 Apple 签名材料、推代码到 GitHub、在控制台填密钥、触发构建

**🔴 安全红线（务必遵守）：**
1. **任何密钥都不要发给我，也不要写进这个目录的任何文件。** 包括：Apple 证书私钥(.p12)、描述文件(.mobileprovision)、App Store Connect API Key(.p8)、`PUSH_APP_SECRET`。
2. 这些值**只填在 Codemagic 控制台的加密环境变量里**（下文第四节）。Codemagic 的加密变量在日志中自动打码，不会泄露。
3. 本包的 `.gitignore` 已忽略 `env_*.json` 和所有证书文件，正常 `git push` 不会带出密钥。但**推之前请再扫一眼** GitHub 上要提交的文件列表，确认没有 `env_release.json`、`*.p12`、`*.p8`。
4. GitHub 仓库**必须设为 Private**。

---

## 一、全流程概览

```
本地(已完成)          你的操作
─────────────        ──────────────────────────────────────
CI 包已就绪    ──►   ① 注册 Codemagic（用 GitHub 账号登录）
                     ② 准备 Apple 签名材料（二选一，见第三节）
                     ③ 把本目录推到一个私有 GitHub 仓库
                     ④ Codemagic 关联该仓库
                     ⑤ 配置环境变量组 youdake_env（填密钥）
                     ⑥ 配置 iOS 签名（绑定证书/profile 或 API Key）
                     ⑦ 点 Start Build，等约 10-20 分钟
                     ⑧ 在 Artifacts 下载 .ipa
```

---

## 二、前置：注册与仓库

### 2.1 注册 Codemagic
- 打开 https://codemagic.io ，用 **GitHub 账号**登录（最省事，后面直接授权拉代码）
- 免费额度：每月 500 分钟构建，单次 iOS 构建约 10-20 分钟，够用

### 2.2 把本 CI 包推到私有 GitHub 仓库
在本目录（`ci-package`）执行：

```bash
cd <这个 ci-package 目录>
git init
git add .
# ⚠️ 提交前务必确认这两个文件不在列表里（应被 .gitignore 挡掉）：
git status            # 检查：不应出现 env_release.json / *.p12 / *.p8 / *.mobileprovision
git commit -m "iOS CI build package v1.0.5"
# 在 GitHub 网页先建一个 Private 空仓库，然后：
git branch -M main
git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin main
```

> 这个包**不是**原 `yunying` 项目的 git 仓库（原项目根本没初始化 git）。它是一个独立的、自带替代库的构建快照。推它不影响你的原项目。

---

## 三、准备 Apple 签名材料（关键，二选一）

IPA 要能装到真机，必须签名。两种方案：

### 方案 A（推荐）：App Store Connect API Key —— Codemagic 自动管理证书
最省事，Codemagic 能自动创建/获取证书和描述文件。

1. 登录 https://appstoreconnect.apple.com → **Users and Access → Integrations → App Store Connect API**
2. 点 **+** 生成一个 Key，权限选 **App Manager**
3. **Download API Key**（.p8 文件，只能下载一次，存好）
4. 记下页面上的 **Issuer ID**，和这个 Key 的 **Key ID**
5. 到 Codemagic：**Team settings → Team integrations → Developer Portal → Manage keys → Add key**
   - 填一个 key 名称（自定义，如 `youdake-asc`）
   - 填 Issuer ID、Key ID，上传 .p8 文件
6. 回到本包 `codemagic.yaml`，把第 28 行占位符换成这个 key 名：
   ```yaml
   integrations:
     app_store_connect: youdake-asc      # ← 换成你上面起的名字
   ```

> ⚠️ .p8、Issuer ID、Key ID 都只填在 Codemagic 控制台，**不要写进任何文件、不要发我**。

### 方案 B：手动上传证书 + 描述文件
若你已有发布证书：

1. 导出 **.p12**（证书+私钥，带密码）：从钥匙串访问 → 找到 "Apple Distribution: 你的团队" → 右键导出
2. 准备 **.mobileprovision**：从 Apple Developer 后台下载，或让 Codemagic 用 API Key 自动 fetch
3. Codemagic：**Team settings → codemagic.yaml settings → Code signing identities**
   - iOS certificates 页：上传 .p12，填密码和 Reference name（如 `youdake_dist_cert`）
   - iOS provisioning profiles 页：上传 .mobileprovision，填 Reference name（如 `youdake_adhoc_profile`）
4. 改 `codemagic.yaml`，把 `ios_signing` 换成按引用名指定（官方规定：用了 reference 就不能再用 distribution_type）：
   ```yaml
   environment:
     ios_signing:
       provisioning_profiles:
         - youdake_adhoc_profile
       certificates:
         - youdake_dist_cert
   ```
   并删掉 `integrations.app_store_connect` 那行。

### 🔴 ad-hoc 分发的额外前提：登记设备 UDID
你选了 `distribution_type: ad_hoc`（内部分发）。**ad-hoc 包只能装到「已在 Apple 后台登记 UDID」的设备上。**
- 收集要安装的设备 UDID（iPhone 连 iTunes/Finder 可看，或用 https://udid.io 这类网页）
- 到 Apple Developer → Devices 里逐个添加
- 描述文件要包含这些设备（方案 A 下 Codemagic 会自动处理；方案 B 下需确保 profile 含这些 UDID）
- 若只想给少数几台测试机装，ad-hoc 合适；若想公开测试用 TestFlight，把 `distribution_type` 改成 `app_store`

---

## 四、配置环境变量组（填后端地址与推送密钥）

`codemagic.yaml` 已声明要用一个名为 `youdake_env` 的加密变量组。你去控制台创建它：

1. Codemagic → 你的 App → **Environment variables → Add group**
2. Group name 填 `youdake_env`，**勾选 Secure**
3. 添加 4 个变量（值从你本机 `yunying\env_release.json` 抄，**别发我**）：

   | 变量名 | 值 |
   |---|---|
   | `ENV` | `release` |
   | `API_HOST` | `https://youdake.com/team/` |
   | `PUSH_APP_KEY` | （你 env_release.json 里的值） |
   | `PUSH_APP_SECRET` | 🔴（你 env_release.json 里的值，机密） |

4. 保存。这 4 个变量名与代码里 `String.fromEnvironment(...)` 读取的键**完全一致**（我已核对：`Const.dart` 读 `ENV`/`API_HOST`，`push_service.dart` 读 `PUSH_APP_KEY`/`PUSH_APP_SECRET`），构建时会经 `--dart-define` 注入。

> `.env.ci.template` 是这个组的模板，方便你对照变量名，但**不要把真实值填进那个文件**。

---

## 五、触发构建

1. Codemagic → 你的 App → **Start your first build** 或 **Start new build**
2. 选 branch `main`、workflow `ios-release`（即 codemagic.yaml 里那个）
3. 点 **Start build**
4. 等 10-20 分钟。构建日志里密钥会被自动打码（显示为 `***`）

构建会依次执行：装 Flutter 3.41.4 → 设置签名 → `pub get`（用 local_deps 替代库）→ `build_runner` → `gen-l10n` → `pod install` → `flutter build ipa`。

---

## 六、下载与安装 IPA

1. 构建成功后，进 **Artifacts** 标签
2. 下载 `优达客运营.ipa`（产物路径 `build/ios/ipa/*.ipa`）
3. 分发安装：
   - **蒲公英/fir.im**：上传 IPA，已登记 UDID 的设备扫码安装
   - **Apple Configurator / Xcode**：连 iPhone 直接装
   - **TestFlight**（若用 app_store 类型）：上传到 App Store Connect，内测组安装

---

## 七、常见错误排查

| 现象 | 原因 | 解决 |
|---|---|---|
| `pub get` 失败、找不到 itwo_flutter_base | local_deps 没推上去，或 pubspec 仍指向 codeup | 确认 `git status` 里 `local_deps/` 已提交；确认 pubspec 是 `path:` 不是 `git:` |
| `No provisioning profile` / 签名失败 | 没配 ios_signing，或 bundle id 不匹配 | 核对 bundle id = `com.youdake.operation.ios`；确认第三、四节都做了 |
| `requires a provisioning profile with the Push Notifications feature` | profile 没开推送能力 | 描述文件的 App ID 需勾选 Push Notifications（本项目 entitlements 含 aps-environment） |
| IPA 装上但打不开/闪退 | ad-hoc 包未登记该设备 UDID | 把设备 UDID 加进 Apple Developer Devices，重新生成 profile 再构建 |
| 装上能开但连不上后端 | 环境变量没注入或域名错 | 确认 youdake_env 组 4 个变量都填了；确认 API_HOST 是你要的 .com |
| 推送收不到 | PUSH_APP_KEY/SECRET 没注入 | 同上，确认加密组里这两个值正确 |
| `pod install` 失败 | CocoaPods 源问题 | codemagic.yaml 已用 `--repo-update`；若仍失败可加国内 pod 源 |

---

## 八、风险提示（同 APK 指引，务必知悉）

1. **替代库非官方原库**。`local_deps/` 里的 `itwo_flutter_base`/`itwo_flutter_net` 是我依据项目 195 处调用反推实现的，已过 42 项行为测试 + Android 真机验证（你反馈可用），但无法保证与原库 100% 一致。iOS 首次构建后，请重点验证：登录（MD5+BCrypt）、token 持久化（退出重进不掉登录）、推送、首页看板与库存刷新。
2. **拿到原库权限后应换回官方依赖重建**：把 `pubspec.yaml` 的两个 `path:` 改回 `git:`，删掉 `local_deps/`，重跑构建。
3. **前后端必须同步发版**：看板接口 `todayRevenue` 由 String 改为数值型，是破坏性变更。后端没部署本次改动的话，首页金额会显示异常。
4. **Flutter 版本**：codemagic.yaml 锁 3.41.4（项目要求）；本机验证用的是 3.47.3。若 CI 上 3.41.4 有兼容问题，可改成 3.47.3（与本机验证环境一致）。

---

## 附：本 CI 包与原项目的差异

| 项 | 原项目 yunying | 本 CI 包 |
|---|---|---|
| 私有依赖 | `git:` 指向 codeup（403） | `path:` 指向 `local_deps/` 替代库 |
| push_config.plist 引用 | 已删除（本机修复） | 已删除（同步） |
| 版本号 | 1.0.5+7 | 1.0.5+7（一致） |
| env_*.json | 在仓库 | 在目录但被 .gitignore 忽略，改用加密变量注入 |
| codemagic.yaml | 无 | 新增 |
| .gitignore | 原项目版 | CI 专用版（额外忽略密钥、保留 local_deps 与 pubspec.lock） |

除上述外，`lib/`、`ios/` 源码与原项目**完全一致**（含本次订单统计、首页看板、库存轮询的全部改动）。
