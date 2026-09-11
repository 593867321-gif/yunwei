import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widget/widet_dialog.dart';

class PermissionUtils {
  /// 单个权限申请与检查 (异步返回结果)
  ///
  /// [context] 上下文，用于检测 mounted 状态及显示引导弹窗
  /// [permission] 需要申请的权限项 (例如: Permission.camera)
  /// [permissionName] 权限的中文显示名称 (例如: "相机")
  ///
  /// 返回值: [Future<bool>]，true 表示已获得授权，false 表示未获得授权或已被拒绝
  static Future<bool> check(BuildContext context, Permission permission, {required String permissionName}) async {
    // 1. 请求权限 (如果已经授权过，方法会直接返回 granted)
    final status = await permission.request();

    // 2. 情况 A: 用户点击允许，已授权
    if (status.isGranted) {
      return true;
    }

    // 3. 情况 B: 被拒绝 (包含普通拒绝和永久拒绝)
    // 在这里我们统一处理引导，如果用户彻底禁用了权限，则弹窗引导去设置页
    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;

      // 这里使用 await 确保弹窗关闭后才返回结果
      await DialogUtil.showConfirmDialog(
        context,
        title: '$permissionName权限受限',
        message: '为了正常使用功能，请点击“去设置”并在系统设置中开启$permissionName权限。',
        confirmText: '去设置',
        onConfirm: () => openAppSettings(), // 打开系统应用设置界面
      );
    } else {
      // 普通拒绝 (isDenied)，通常可以不做处理，或者轻提示
      // "需要$permissionName权限".toast();
    }

    return false;
  }

  /// 多个权限检查 (返回 Future<bool>)
  /// [permissions] 权限列表
  /// [tipsName] 业务功能名称，用于弹窗描述
  static Future<bool> checkMulti(BuildContext context, List<Permission> permissions, {required String tipsName}) async {
    // 1. 请求权限
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // 2. 统计状态
    bool isAllGranted = true;
    bool isAnyPermanentlyDenied = false;

    statuses.forEach((permission, status) {
      if (!status.isGranted) isAllGranted = false;
      if (status.isPermanentlyDenied) isAnyPermanentlyDenied = true;
    });

    // 3. 情况 A: 全部通过
    if (isAllGranted) return true;

    // 4. 情况 B: 只要有一个被永久拒绝，弹窗引导
    if (isAnyPermanentlyDenied) {
      if (!context.mounted) return false;
      await DialogUtil.showConfirmDialog(context, title: '权限申请', message: '使用“$tipsName”功能需要相关权限，您已禁用部分权限，请在设置中手动开启。', confirmText: '去设置', onConfirm: () => openAppSettings());
    }

    // 其余情况（普通拒绝）直接返回 false，业务层可自行决定是否提示
    return false;
  }
}
