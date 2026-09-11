import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'优达客运营'**
  String get appTitle;

  /// 登录页账号输入框标签
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get loginAccountLabel;

  /// 登录页账号输入框占位文本
  ///
  /// In zh, this message translates to:
  /// **'请输入账号'**
  String get loginAccountHint;

  /// 登录页密码输入框标签
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get loginPasswordLabel;

  /// 登录页密码输入框占位文本
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get loginPasswordHint;

  /// 登录按钮文本
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginButton;

  /// 登录页欢迎回来文案
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来'**
  String get loginWelcomeBack;

  /// 登录页副标题
  ///
  /// In zh, this message translates to:
  /// **'请登录以继续'**
  String get loginPleaseSignIn;

  /// 账号密码为空时的提示
  ///
  /// In zh, this message translates to:
  /// **'请输入账号和密码'**
  String get loginErrorEmpty;

  /// 登录失败时的提示
  ///
  /// In zh, this message translates to:
  /// **'登录失败'**
  String get loginErrorFailed;

  /// 首页顶部标题
  ///
  /// In zh, this message translates to:
  /// **'运维工作台'**
  String get homePageTitle;

  /// 首页欢迎语，带用户名
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来，{userName}'**
  String homeWelcomeBack(String userName);

  /// 首页管理域标签
  ///
  /// In zh, this message translates to:
  /// **'管理域：{domain}'**
  String homeDomainLabel(String domain);

  /// 首页统计-今日订单数
  ///
  /// In zh, this message translates to:
  /// **'今日订单数'**
  String get homeStatTodayOrders;

  /// 首页统计-今日营业额
  ///
  /// In zh, this message translates to:
  /// **'今日营业额'**
  String get homeStatTodayRevenue;

  /// 首页统计-其他支付收入（除余额外的支付方式，当前为微信）
  ///
  /// In zh, this message translates to:
  /// **'其他支付收入'**
  String get homeStatOtherPay;

  /// 首页统计-用户余额支付实收收入
  ///
  /// In zh, this message translates to:
  /// **'用户余额支付'**
  String get homeStatBalancePay;

  /// 首页统计-金额单位（数值保留一位小数，如 8888.8 元）
  ///
  /// In zh, this message translates to:
  /// **'元'**
  String get homeStatAmountUnit;

  /// 首页统计-订单/工单数量单位
  ///
  /// In zh, this message translates to:
  /// **'单'**
  String get homeStatOrderUnit;

  /// 首页设备状态-在线设备
  ///
  /// In zh, this message translates to:
  /// **'在线设备'**
  String get homeDeviceStatusOnline;

  /// 首页设备状态-库存预警
  ///
  /// In zh, this message translates to:
  /// **'库存预警'**
  String get homeDeviceStatusAlert;

  /// 业务功能-库存管理
  ///
  /// In zh, this message translates to:
  /// **'库存管理'**
  String get homeMenuInventory;

  /// 业务功能-扫一扫
  ///
  /// In zh, this message translates to:
  /// **'扫一扫'**
  String get homeMenuScan;

  /// 业务功能-设备列表
  ///
  /// In zh, this message translates to:
  /// **'设备列表'**
  String get homeMenuDevices;

  /// 业务功能-订单记录
  ///
  /// In zh, this message translates to:
  /// **'订单记录'**
  String get homeMenuOrders;

  /// 业务功能-故障维修
  ///
  /// In zh, this message translates to:
  /// **'故障维修'**
  String get homeMenuRepair;

  /// 业务功能-报表数据
  ///
  /// In zh, this message translates to:
  /// **'报表数据'**
  String get homeMenuReport;

  /// 业务功能区域标题
  ///
  /// In zh, this message translates to:
  /// **'业务功能'**
  String get homeBusinessTitle;

  /// 即时预警区域标题
  ///
  /// In zh, this message translates to:
  /// **'即时预警'**
  String get homeAlertTitle;

  /// 扫码失败提示
  ///
  /// In zh, this message translates to:
  /// **'扫码失败'**
  String get homeScanFailed;

  /// 相机权限名称
  ///
  /// In zh, this message translates to:
  /// **'相机权限'**
  String get homeCameraPermission;

  /// 默认用户名
  ///
  /// In zh, this message translates to:
  /// **'系统管理员'**
  String get homeSystemAdmin;

  /// 默认管理域标签
  ///
  /// In zh, this message translates to:
  /// **'全部设备'**
  String get homeAllDevices;

  /// 库存管理页面标题
  ///
  /// In zh, this message translates to:
  /// **'库存管理'**
  String get stockPageTitle;

  /// 未选择设备时的提示
  ///
  /// In zh, this message translates to:
  /// **'请先选择一台设备'**
  String get stockSelectDeviceFirst;

  /// 库存管理需要选择具体设备的提示
  ///
  /// In zh, this message translates to:
  /// **'库存管理需要选择具体设备'**
  String get stockSelectDeviceHint;

  /// 选择设备按钮
  ///
  /// In zh, this message translates to:
  /// **'选择设备'**
  String get stockSelectDeviceButton;

  /// 库存列表头部计数
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 项'**
  String stockTotalCount(int count);

  /// 库存列表为空时的提示
  ///
  /// In zh, this message translates to:
  /// **'暂无库存数据'**
  String get stockEmptyHint;

  /// 库存模式-云端计算
  ///
  /// In zh, this message translates to:
  /// **'云端计算'**
  String get stockModeCloudCalc;

  /// 库存模式-硬件采集
  ///
  /// In zh, this message translates to:
  /// **'硬件采集'**
  String get stockModeHwCollect;

  /// 库存模式-设备计算
  ///
  /// In zh, this message translates to:
  /// **'设备计算'**
  String get stockModeHwCalc;

  /// 库存模式-未知
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get stockModeUnknown;

  /// 库存模式-无限
  ///
  /// In zh, this message translates to:
  /// **'无限'**
  String get stockModeInfinite;

  /// 物料类型-杯子
  ///
  /// In zh, this message translates to:
  /// **'杯子'**
  String get stockMaterialCup;

  /// 物料类型-盖子
  ///
  /// In zh, this message translates to:
  /// **'盖子'**
  String get stockMaterialCap;

  /// 物料类型-牛奶
  ///
  /// In zh, this message translates to:
  /// **'牛奶'**
  String get stockMaterialMilk;

  /// 物料类型-咖啡豆
  ///
  /// In zh, this message translates to:
  /// **'咖啡豆'**
  String get stockMaterialCoffeeBean;

  /// 物料类型-水
  ///
  /// In zh, this message translates to:
  /// **'水'**
  String get stockMaterialWater;

  /// 物料类型-糖浆
  ///
  /// In zh, this message translates to:
  /// **'糖浆'**
  String get stockMaterialSyrup;

  /// 物料类型-二氧化碳
  ///
  /// In zh, this message translates to:
  /// **'二氧化碳'**
  String get stockMaterialCO2;

  /// 库存变更标记
  ///
  /// In zh, this message translates to:
  /// **'已修改'**
  String get stockChanged;

  /// 未绑定物料的占位文本
  ///
  /// In zh, this message translates to:
  /// **'未绑定物料'**
  String get stockNoMaterial;

  /// 更换物料按钮
  ///
  /// In zh, this message translates to:
  /// **'更换物料'**
  String get stockChangeMaterial;

  /// 修改库存操作文本
  ///
  /// In zh, this message translates to:
  /// **'修改库存'**
  String get stockEdit;

  /// 补货操作文本
  ///
  /// In zh, this message translates to:
  /// **'补货'**
  String get stockReplenish;

  /// 当前库存显示
  ///
  /// In zh, this message translates to:
  /// **'当前库存：{value} {unit}'**
  String stockCurrentStock(int value, String unit);

  /// 最大容量显示
  ///
  /// In zh, this message translates to:
  /// **'最大容量：{value} {unit}'**
  String stockMaxStock(int value, String unit);

  /// 修改库存弹窗提示
  ///
  /// In zh, this message translates to:
  /// **'输入新的库存数量'**
  String get stockEditHint;

  /// 补货弹窗提示
  ///
  /// In zh, this message translates to:
  /// **'输入本次补货量'**
  String get stockReplenishHint;

  /// 库存编辑-数量输入占位
  ///
  /// In zh, this message translates to:
  /// **'请输入数量'**
  String get stockInputHint;

  /// 库存编辑-可选数量模式提示
  ///
  /// In zh, this message translates to:
  /// **'选填，留空则仅记录操作'**
  String get stockOptionalHint;

  /// 无效数量提示
  ///
  /// In zh, this message translates to:
  /// **'请输入有效数量'**
  String get stockInvalidNumber;

  /// 加载物料列表时的提示
  ///
  /// In zh, this message translates to:
  /// **'加载物料列表...'**
  String get stockLoadingMaterials;

  /// 物料选择弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'选择「{type}」物料'**
  String stockPickMaterialTitle(String type);

  /// 物料选择弹窗-当前物料
  ///
  /// In zh, this message translates to:
  /// **'当前：{name}'**
  String stockCurrentMaterial(String name);

  /// 物料选择弹窗-暂无物料
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get stockCurrentMaterialNone;

  /// 物料选择弹窗-无可用物料
  ///
  /// In zh, this message translates to:
  /// **'无可用物料'**
  String get stockNoAvailableMaterial;

  /// 物料选择-未知物料
  ///
  /// In zh, this message translates to:
  /// **'未知物料'**
  String get stockUnknownMaterial;

  /// 物料加载失败提示
  ///
  /// In zh, this message translates to:
  /// **'物料加载失败，请重试'**
  String get stockLoadMaterialsFailed;

  /// 确认提交标题
  ///
  /// In zh, this message translates to:
  /// **'确认提交'**
  String get stockConfirmSubmit;

  /// 确认提交消息
  ///
  /// In zh, this message translates to:
  /// **'即将提交 {count} 项库存变更，设备可能需要一定时间响应。'**
  String stockConfirmMessage(int count);

  /// 同步库存中的提示
  ///
  /// In zh, this message translates to:
  /// **'正在同步设备库存...'**
  String get stockSyncing;

  /// 库存更新成功提示
  ///
  /// In zh, this message translates to:
  /// **'库存更新成功'**
  String get stockUpdateSuccess;

  /// 库存更新失败提示
  ///
  /// In zh, this message translates to:
  /// **'库存更新失败'**
  String get stockUpdateFailed;

  /// 提交按钮带计数
  ///
  /// In zh, this message translates to:
  /// **'提交补货（{count}项变更）'**
  String stockSubmitButton(int count);

  /// 无变更时的按钮文本
  ///
  /// In zh, this message translates to:
  /// **'无变更项'**
  String get stockNoChanges;

  /// 撤销修改按钮
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get stockUndo;

  /// 未命名组件的占位文本
  ///
  /// In zh, this message translates to:
  /// **'未命名组件'**
  String get stockUnnamedComponent;

  /// 库存保存方式选择标签
  ///
  /// In zh, this message translates to:
  /// **'保存方式'**
  String get stockSaveMode;

  /// 库存级别-库存充足（HW_COLLECT/UNKNOWN 模式状态值=2）
  ///
  /// In zh, this message translates to:
  /// **'库存充足'**
  String get stockLevelNormal;

  /// 库存级别-需补货（HW_COLLECT/UNKNOWN 模式状态值=1）
  ///
  /// In zh, this message translates to:
  /// **'需补货'**
  String get stockLevelLowStock;

  /// 库存级别-售罄（HW_COLLECT/UNKNOWN 模式状态值=0）
  ///
  /// In zh, this message translates to:
  /// **'售罄'**
  String get stockLevelSoldOut;

  /// HW_COLLECT/UNKNOWN 模式的补货按钮文案
  ///
  /// In zh, this message translates to:
  /// **'补货（仅记录）'**
  String get stockStatusRefillRecordOnly;

  /// 库存流水记录-HW_COLLECT/UNKNOWN 模式的预扣流水标注
  ///
  /// In zh, this message translates to:
  /// **'状态值模式，仅记录流水'**
  String get stockRecordStatusModeHint;

  /// 设备抽屉标题
  ///
  /// In zh, this message translates to:
  /// **'选择管理域'**
  String get drawerTitle;

  /// 设备抽屉搜索框占位文本
  ///
  /// In zh, this message translates to:
  /// **'搜索设备名称或编号'**
  String get drawerSearchHint;

  /// 设备抽屉-全部设备选项
  ///
  /// In zh, this message translates to:
  /// **'全部设备'**
  String get drawerAllDevices;

  /// 设备抽屉-默认运营商名称
  ///
  /// In zh, this message translates to:
  /// **'运营商'**
  String get drawerDefaultOperator;

  /// 设备抽屉-默认店铺名称
  ///
  /// In zh, this message translates to:
  /// **'店铺'**
  String get drawerDefaultStore;

  /// 设备抽屉-默认设备名称
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get drawerDefaultDevice;

  /// 通用取消按钮
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// 通用确定按钮
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirm;

  /// 退出登录按钮
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get commonLogout;

  /// 退出登录确认提示
  ///
  /// In zh, this message translates to:
  /// **'确认退出登录吗？'**
  String get commonLogoutConfirm;

  /// 扫码成功弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'扫码成功'**
  String get dialogScanSuccess;

  /// 扫码成功弹窗-二维码秘钥
  ///
  /// In zh, this message translates to:
  /// **'二维码秘钥：{code}'**
  String dialogScanCode(String code);

  /// 弹窗关闭按钮
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get dialogClose;

  /// 库存记录页面标题
  ///
  /// In zh, this message translates to:
  /// **'库存流水记录'**
  String get stockRecordTitle;

  /// 库存记录筛选-全部
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get stockRecordAll;

  /// 库存记录加载失败重试提示
  ///
  /// In zh, this message translates to:
  /// **'加载失败，点击重试'**
  String get stockRecordRetry;

  /// 库存记录空状态
  ///
  /// In zh, this message translates to:
  /// **'暂无库存变动记录'**
  String get stockRecordEmpty;

  /// 设备列表页面标题
  ///
  /// In zh, this message translates to:
  /// **'设备列表'**
  String get deviceListTitle;

  /// 设备列表搜索框占位文本
  ///
  /// In zh, this message translates to:
  /// **'搜索设备名称/编号/型号'**
  String get deviceListSearchHint;

  /// 设备列表筛选-全部
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get deviceListFilterAll;

  /// 设备列表筛选-在线
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get deviceListFilterOnline;

  /// 设备列表筛选-离线
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get deviceListFilterOffline;

  /// 设备列表空状态提示
  ///
  /// In zh, this message translates to:
  /// **'暂无设备数据'**
  String get deviceListEmpty;

  /// 设备列表告警/故障过多时的折叠计数
  ///
  /// In zh, this message translates to:
  /// **'+{count}'**
  String deviceListAlertMore(int count);

  /// 设备列表头部计数
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 台设备'**
  String deviceListTotalCount(int count);

  /// 设备列表-库存缺货标记
  ///
  /// In zh, this message translates to:
  /// **'缺货'**
  String get deviceListSoldOut;

  /// 设备列表-低库存预警标记
  ///
  /// In zh, this message translates to:
  /// **'低库存'**
  String get deviceListLowStock;

  /// 设备列表-电气数据冷水温度前缀
  ///
  /// In zh, this message translates to:
  /// **'冷水'**
  String get deviceListColdWater;

  /// 设备列表-无故障告警时的占位文本
  ///
  /// In zh, this message translates to:
  /// **'无故障报警'**
  String get deviceListNoAlert;

  /// 设备列表-无库存预警时的占位文本
  ///
  /// In zh, this message translates to:
  /// **'无预警'**
  String get deviceListNoStockAlert;

  /// 设备列表卡片-库存按钮
  ///
  /// In zh, this message translates to:
  /// **'库存'**
  String get deviceListBtnStock;

  /// 设备列表卡片-状态按钮
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get deviceListBtnStatus;

  /// 设备列表卡片-控制按钮
  ///
  /// In zh, this message translates to:
  /// **'控制'**
  String get deviceListBtnControl;

  /// 设备列表卡片-无不可用组件
  ///
  /// In zh, this message translates to:
  /// **'无不可用组件'**
  String get deviceListNoUnavailable;

  /// 设备详情页标题占位
  ///
  /// In zh, this message translates to:
  /// **'设备详情'**
  String get deviceDetailTitle;

  /// 设备详情-运行状态区块标题
  ///
  /// In zh, this message translates to:
  /// **'运行状态'**
  String get deviceDetailSectionStatus;

  /// 设备详情-电力参数区块标题
  ///
  /// In zh, this message translates to:
  /// **'电力参数'**
  String get deviceDetailSectionPower;

  /// 设备详情-温度参数区块标题
  ///
  /// In zh, this message translates to:
  /// **'温度参数'**
  String get deviceDetailSectionTemp;

  /// 设备详情-水路参数区块标题
  ///
  /// In zh, this message translates to:
  /// **'水路参数'**
  String get deviceDetailSectionWater;

  /// 设备详情-奶路称重区块标题
  ///
  /// In zh, this message translates to:
  /// **'奶路称重'**
  String get deviceDetailSectionMilk;

  /// 设备详情-故障告警区块标题
  ///
  /// In zh, this message translates to:
  /// **'故障告警'**
  String get deviceDetailSectionAlert;

  /// 设备详情-库存预警区块标题
  ///
  /// In zh, this message translates to:
  /// **'库存预警'**
  String get deviceDetailSectionStockAlert;

  /// 设备详情-无数据占位文本
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get deviceDetailNoData;

  /// 设备详情-系统缺水正常状态
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get deviceDetailNormal;

  /// 设备详情-系统缺水告警状态
  ///
  /// In zh, this message translates to:
  /// **'缺水'**
  String get deviceDetailWaterShortage;

  /// 设备详情-设备编号标签
  ///
  /// In zh, this message translates to:
  /// **'设备编号'**
  String get deviceDetailLabelDeviceCode;

  /// 设备详情-设备型号标签
  ///
  /// In zh, this message translates to:
  /// **'设备型号'**
  String get deviceDetailLabelModel;

  /// 设备详情-在线事件区块标题
  ///
  /// In zh, this message translates to:
  /// **'在线事件'**
  String get deviceOnlineEvents;

  /// 设备详情-故障历史区块标题
  ///
  /// In zh, this message translates to:
  /// **'故障历史'**
  String get deviceFaultHistory;

  /// 设备详情-在线事件-在线标签
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get deviceOnline;

  /// 设备详情-在线事件-离线标签
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get deviceOffline;

  /// 告警列表页面标题
  ///
  /// In zh, this message translates to:
  /// **'告警列表'**
  String get alertPageTitle;

  /// 告警筛选-全部
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get alertFilterAll;

  /// 告警筛选-设备故障
  ///
  /// In zh, this message translates to:
  /// **'故障'**
  String get alertFilterFault;

  /// 告警筛选-设备告警
  ///
  /// In zh, this message translates to:
  /// **'告警'**
  String get alertFilterWarning;

  /// 告警筛选-缺货预警
  ///
  /// In zh, this message translates to:
  /// **'缺货'**
  String get alertFilterStockOut;

  /// 告警状态-新告警
  ///
  /// In zh, this message translates to:
  /// **'新告警'**
  String get alertStatusNew;

  /// 告警状态-已确认
  ///
  /// In zh, this message translates to:
  /// **'已确认'**
  String get alertStatusAcknowledged;

  /// 告警状态-已消除
  ///
  /// In zh, this message translates to:
  /// **'已消除'**
  String get alertStatusResolved;

  /// 告警时间标签
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get alertTimeLabel;

  /// 告警发生次数
  ///
  /// In zh, this message translates to:
  /// **'发生 {count} 次'**
  String alertOccurrenceCount(int count);

  /// 告警列表头部计数
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条告警'**
  String alertTotalCount(int count);

  /// 告警列表空状态
  ///
  /// In zh, this message translates to:
  /// **'暂无告警记录'**
  String get alertEmpty;

  /// 告警操作-确认按钮
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get alertBtnAcknowledge;

  /// 告警操作-消除按钮
  ///
  /// In zh, this message translates to:
  /// **'消除'**
  String get alertBtnResolve;

  /// 告警批量操作栏标题
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项'**
  String alertBatchTitle(int count);

  /// 告警批量确认提示
  ///
  /// In zh, this message translates to:
  /// **'确认将 {count} 条告警标记为已确认？'**
  String alertBatchAcknowledgeConfirm(int count);

  /// 告警批量消除提示
  ///
  /// In zh, this message translates to:
  /// **'确认将 {count} 条告警标记为已消除？'**
  String alertBatchResolveConfirm(int count);

  /// 告警操作成功提示
  ///
  /// In zh, this message translates to:
  /// **'操作成功'**
  String get alertOperationSuccess;

  /// 告警操作失败提示
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get alertOperationFailed;

  /// 告警列表全部加载完成
  ///
  /// In zh, this message translates to:
  /// **'已加载全部告警'**
  String get alertLoadedAll;

  /// 首页告警计数-故障
  ///
  /// In zh, this message translates to:
  /// **'故障'**
  String get homeAlertFaultCount;

  /// 首页告警计数-设备告警
  ///
  /// In zh, this message translates to:
  /// **'告警'**
  String get homeAlertWarningCount;

  /// 首页告警计数-缺货
  ///
  /// In zh, this message translates to:
  /// **'缺货'**
  String get homeAlertStockOutCount;

  /// 首页告警区域-查看全部按钮
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get homeAlertViewAll;

  /// 首页告警区域-无告警提示
  ///
  /// In zh, this message translates to:
  /// **'暂无告警'**
  String get homeAlertNoAlerts;

  /// 取消工单弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'取消工单'**
  String get orderCancelTitle;

  /// 强制取消工单弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'强制取消工单'**
  String get orderCancelForceTitle;

  /// 强制取消 MAKING 工单时的风险提示
  ///
  /// In zh, this message translates to:
  /// **'制作中的工单无法确认原料是否已消耗，取消后不会退回原料库存'**
  String get orderCancelWarning;

  /// 强制取消时的风险确认勾选文案
  ///
  /// In zh, this message translates to:
  /// **'我已了解风险，确认操作'**
  String get orderCancelRiskConfirm;

  /// 取消工单提交成功提示
  ///
  /// In zh, this message translates to:
  /// **'取消工单已提交'**
  String get orderCancelSubmit;

  /// 批量取消弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'批量取消工单'**
  String get orderBatchCancelTitle;

  /// 批量取消提交成功提示
  ///
  /// In zh, this message translates to:
  /// **'批量取消请求已提交'**
  String get orderBatchCancelSubmit;

  /// 丢杯指令已发送成功提示
  ///
  /// In zh, this message translates to:
  /// **'丢杯指令已发送'**
  String get orderDiscardSent;

  /// 工单详情-查看关联库存流水按钮
  ///
  /// In zh, this message translates to:
  /// **'查看库存流水'**
  String get orderViewStockRecords;

  /// 取消原因展示格式
  ///
  /// In zh, this message translates to:
  /// **'取消原因：{reason}'**
  String orderCancelReason(String reason);

  /// No description provided for @remoteControlTitle.
  ///
  /// In zh, this message translates to:
  /// **'远程控制'**
  String get remoteControlTitle;

  /// No description provided for @remoteControlIdle.
  ///
  /// In zh, this message translates to:
  /// **'未控制'**
  String get remoteControlIdle;

  /// No description provided for @remoteControlControlling.
  ///
  /// In zh, this message translates to:
  /// **'控制中'**
  String get remoteControlControlling;

  /// No description provided for @remoteControlOccupied.
  ///
  /// In zh, this message translates to:
  /// **'已被控制'**
  String get remoteControlOccupied;

  /// No description provided for @remoteControlAcquire.
  ///
  /// In zh, this message translates to:
  /// **'申请控制权'**
  String get remoteControlAcquire;

  /// No description provided for @remoteControlRelease.
  ///
  /// In zh, this message translates to:
  /// **'释放'**
  String get remoteControlRelease;

  /// No description provided for @remoteControlStatusOverview.
  ///
  /// In zh, this message translates to:
  /// **'设备状态总览'**
  String get remoteControlStatusOverview;

  /// No description provided for @remoteControlOnline.
  ///
  /// In zh, this message translates to:
  /// **'● 在线'**
  String get remoteControlOnline;

  /// No description provided for @remoteControlRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get remoteControlRunning;

  /// No description provided for @remoteControlRelay.
  ///
  /// In zh, this message translates to:
  /// **'继电器'**
  String get remoteControlRelay;

  /// No description provided for @remoteControlRobot.
  ///
  /// In zh, this message translates to:
  /// **'机械臂'**
  String get remoteControlRobot;

  /// No description provided for @remoteControlDoorSection.
  ///
  /// In zh, this message translates to:
  /// **'出餐门'**
  String get remoteControlDoorSection;

  /// No description provided for @remoteControlCupSection.
  ///
  /// In zh, this message translates to:
  /// **'落杯'**
  String get remoteControlCupSection;

  /// No description provided for @remoteControlLidSection.
  ///
  /// In zh, this message translates to:
  /// **'落盖'**
  String get remoteControlLidSection;

  /// No description provided for @remoteControlCoffeeSection.
  ///
  /// In zh, this message translates to:
  /// **'咖啡机'**
  String get remoteControlCoffeeSection;

  /// No description provided for @remoteControlIceSection.
  ///
  /// In zh, this message translates to:
  /// **'制冰'**
  String get remoteControlIceSection;

  /// No description provided for @remoteControlJuiceSection.
  ///
  /// In zh, this message translates to:
  /// **'果汁'**
  String get remoteControlJuiceSection;

  /// No description provided for @remoteControlNeedControlHint.
  ///
  /// In zh, this message translates to:
  /// **'请先申请控制权'**
  String get remoteControlNeedControlHint;

  /// No description provided for @remoteControlOpTargetArm.
  ///
  /// In zh, this message translates to:
  /// **'目标臂'**
  String get remoteControlOpTargetArm;

  /// No description provided for @remoteControlOpActions.
  ///
  /// In zh, this message translates to:
  /// **'动作'**
  String get remoteControlOpActions;

  /// No description provided for @remoteControlOpLinkDoor.
  ///
  /// In zh, this message translates to:
  /// **'联动'**
  String get remoteControlOpLinkDoor;

  /// No description provided for @remoteControlOpCupMotor.
  ///
  /// In zh, this message translates to:
  /// **'杯托'**
  String get remoteControlOpCupMotor;

  /// No description provided for @remoteControlOpFrontDoor.
  ///
  /// In zh, this message translates to:
  /// **'前门'**
  String get remoteControlOpFrontDoor;

  /// No description provided for @remoteControlOpMachine.
  ///
  /// In zh, this message translates to:
  /// **'机号'**
  String get remoteControlOpMachine;

  /// No description provided for @remoteControlOpIceMode.
  ///
  /// In zh, this message translates to:
  /// **'模式'**
  String get remoteControlOpIceMode;

  /// No description provided for @remoteControlOpJuicePipe.
  ///
  /// In zh, this message translates to:
  /// **'管路'**
  String get remoteControlOpJuicePipe;

  /// No description provided for @remoteControlSensorData.
  ///
  /// In zh, this message translates to:
  /// **'传感器数据'**
  String get remoteControlSensorData;

  /// No description provided for @remoteControlSystemSection.
  ///
  /// In zh, this message translates to:
  /// **'系统指令'**
  String get remoteControlSystemSection;

  /// No description provided for @remoteControlVersionSection.
  ///
  /// In zh, this message translates to:
  /// **'固件版本'**
  String get remoteControlVersionSection;

  /// No description provided for @remoteControlQueryVersion.
  ///
  /// In zh, this message translates to:
  /// **'查询版本'**
  String get remoteControlQueryVersion;

  /// No description provided for @remoteControlExecuteClean.
  ///
  /// In zh, this message translates to:
  /// **'执行清理'**
  String get remoteControlExecuteClean;

  /// No description provided for @remoteControlReset.
  ///
  /// In zh, this message translates to:
  /// **'复位'**
  String get remoteControlReset;

  /// No description provided for @remoteControlRestart.
  ///
  /// In zh, this message translates to:
  /// **'重启'**
  String get remoteControlRestart;

  /// No description provided for @remoteControlCleanAll.
  ///
  /// In zh, this message translates to:
  /// **'全清'**
  String get remoteControlCleanAll;

  /// No description provided for @remoteControlCleanSpec.
  ///
  /// In zh, this message translates to:
  /// **'指定'**
  String get remoteControlCleanSpec;

  /// No description provided for @remoteControlArm1.
  ///
  /// In zh, this message translates to:
  /// **'① 号臂'**
  String get remoteControlArm1;

  /// No description provided for @remoteControlArm2.
  ///
  /// In zh, this message translates to:
  /// **'② 号臂'**
  String get remoteControlArm2;

  /// No description provided for @remoteControlNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get remoteControlNoData;

  /// No description provided for @remoteControlTooltip.
  ///
  /// In zh, this message translates to:
  /// **'远程控制'**
  String get remoteControlTooltip;

  /// No description provided for @remoteControlRelayFan.
  ///
  /// In zh, this message translates to:
  /// **'风扇'**
  String get remoteControlRelayFan;

  /// No description provided for @remoteControlRelayHeater.
  ///
  /// In zh, this message translates to:
  /// **'加热'**
  String get remoteControlRelayHeater;

  /// No description provided for @remoteControlRelayCooler.
  ///
  /// In zh, this message translates to:
  /// **'制冷'**
  String get remoteControlRelayCooler;

  /// No description provided for @remoteControlRelayLight.
  ///
  /// In zh, this message translates to:
  /// **'照明'**
  String get remoteControlRelayLight;

  /// No description provided for @remoteControlRelayPump.
  ///
  /// In zh, this message translates to:
  /// **'水泵'**
  String get remoteControlRelayPump;

  /// No description provided for @remoteControlRelayCompressor.
  ///
  /// In zh, this message translates to:
  /// **'压缩机'**
  String get remoteControlRelayCompressor;

  /// No description provided for @remoteControlArmReset.
  ///
  /// In zh, this message translates to:
  /// **'复位'**
  String get remoteControlArmReset;

  /// No description provided for @remoteControlArmEnable.
  ///
  /// In zh, this message translates to:
  /// **'上使能'**
  String get remoteControlArmEnable;

  /// No description provided for @remoteControlArmDisable.
  ///
  /// In zh, this message translates to:
  /// **'下使能'**
  String get remoteControlArmDisable;

  /// No description provided for @remoteControlArmRun.
  ///
  /// In zh, this message translates to:
  /// **'运行程序'**
  String get remoteControlArmRun;

  /// No description provided for @remoteControlArmStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get remoteControlArmStop;

  /// No description provided for @remoteControlArmDragEnter.
  ///
  /// In zh, this message translates to:
  /// **'进入拖拽'**
  String get remoteControlArmDragEnter;

  /// No description provided for @remoteControlArmDragExit.
  ///
  /// In zh, this message translates to:
  /// **'退出拖拽'**
  String get remoteControlArmDragExit;

  /// No description provided for @remoteControlArmContinue.
  ///
  /// In zh, this message translates to:
  /// **'压盖位继续'**
  String get remoteControlArmContinue;

  /// No description provided for @remoteControlArmDropOrigin.
  ///
  /// In zh, this message translates to:
  /// **'原点丢杯'**
  String get remoteControlArmDropOrigin;

  /// No description provided for @remoteControlArmDropCache.
  ///
  /// In zh, this message translates to:
  /// **'缓存丢杯'**
  String get remoteControlArmDropCache;

  /// No description provided for @remoteControlArmDropOutlet.
  ///
  /// In zh, this message translates to:
  /// **'出杯口丢杯'**
  String get remoteControlArmDropOutlet;

  /// No description provided for @remoteControlArmSelectAction.
  ///
  /// In zh, this message translates to:
  /// **'选择动作'**
  String get remoteControlArmSelectAction;

  /// No description provided for @remoteControlArmSelectActionHint.
  ///
  /// In zh, this message translates to:
  /// **'请先选择机械臂动作'**
  String get remoteControlArmSelectActionHint;

  /// No description provided for @remoteControlArmStart.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get remoteControlArmStart;

  /// No description provided for @remoteControlParamNone.
  ///
  /// In zh, this message translates to:
  /// **'不涉及'**
  String get remoteControlParamNone;

  /// No description provided for @remoteControlConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认操作'**
  String get remoteControlConfirmTitle;

  /// No description provided for @remoteControlConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确认执行「{action}」？'**
  String remoteControlConfirmMessage(String action);

  /// No description provided for @remoteControlConfirmOk.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get remoteControlConfirmOk;

  /// No description provided for @remoteControlConfirmCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get remoteControlConfirmCancel;

  /// No description provided for @remoteControlCoffeeBrew.
  ///
  /// In zh, this message translates to:
  /// **'出咖啡'**
  String get remoteControlCoffeeBrew;

  /// No description provided for @remoteControlCoffeeRinse.
  ///
  /// In zh, this message translates to:
  /// **'润湿'**
  String get remoteControlCoffeeRinse;

  /// No description provided for @remoteControlCupDispense.
  ///
  /// In zh, this message translates to:
  /// **'落杯'**
  String get remoteControlCupDispense;

  /// No description provided for @remoteControlLidDispense.
  ///
  /// In zh, this message translates to:
  /// **'落盖'**
  String get remoteControlLidDispense;

  /// No description provided for @remoteControlDoorOpen.
  ///
  /// In zh, this message translates to:
  /// **'开门'**
  String get remoteControlDoorOpen;

  /// No description provided for @remoteControlDoorClose.
  ///
  /// In zh, this message translates to:
  /// **'关门'**
  String get remoteControlDoorClose;

  /// No description provided for @remoteControlIceStart.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get remoteControlIceStart;

  /// No description provided for @remoteControlIceWeightMode.
  ///
  /// In zh, this message translates to:
  /// **'克重'**
  String get remoteControlIceWeightMode;

  /// No description provided for @remoteControlIceContinuousMode.
  ///
  /// In zh, this message translates to:
  /// **'连续'**
  String get remoteControlIceContinuousMode;

  /// No description provided for @remoteControlResetAction.
  ///
  /// In zh, this message translates to:
  /// **'复位'**
  String get remoteControlResetAction;

  /// No description provided for @remoteControlJuiceDispense.
  ///
  /// In zh, this message translates to:
  /// **'果汁出料'**
  String get remoteControlJuiceDispense;

  /// No description provided for @remoteControlJuicePipe.
  ///
  /// In zh, this message translates to:
  /// **'管{pipe}'**
  String remoteControlJuicePipe(int pipe);

  /// No description provided for @remoteControlJuiceGramsHint.
  ///
  /// In zh, this message translates to:
  /// **'克重'**
  String get remoteControlJuiceGramsHint;

  /// No description provided for @remoteControlJuiceStart.
  ///
  /// In zh, this message translates to:
  /// **'出料'**
  String get remoteControlJuiceStart;

  /// No description provided for @remoteControlJuiceInvalidParams.
  ///
  /// In zh, this message translates to:
  /// **'管路或克重参数无效'**
  String get remoteControlJuiceInvalidParams;

  /// No description provided for @remoteControlCmdSuccess.
  ///
  /// In zh, this message translates to:
  /// **'{cmd} 成功'**
  String remoteControlCmdSuccess(String cmd);

  /// No description provided for @remoteControlCmdFailed.
  ///
  /// In zh, this message translates to:
  /// **'{cmd} 失败: {reason}'**
  String remoteControlCmdFailed(String cmd, String reason);

  /// No description provided for @remoteControlDropParams.
  ///
  /// In zh, this message translates to:
  /// **'丢杯定位参数'**
  String get remoteControlDropParams;

  /// No description provided for @remoteControlDropTarget.
  ///
  /// In zh, this message translates to:
  /// **'丢杯目标'**
  String get remoteControlDropTarget;

  /// No description provided for @remoteControlDropTargetCoffee.
  ///
  /// In zh, this message translates to:
  /// **'咖啡位'**
  String get remoteControlDropTargetCoffee;

  /// No description provided for @remoteControlDropTargetCache1.
  ///
  /// In zh, this message translates to:
  /// **'缓存1'**
  String get remoteControlDropTargetCache1;

  /// No description provided for @remoteControlDropTargetCache2.
  ///
  /// In zh, this message translates to:
  /// **'缓存2'**
  String get remoteControlDropTargetCache2;

  /// No description provided for @remoteControlDropTargetCache3.
  ///
  /// In zh, this message translates to:
  /// **'缓存3'**
  String get remoteControlDropTargetCache3;

  /// No description provided for @remoteControlDropCupOut.
  ///
  /// In zh, this message translates to:
  /// **'出餐门'**
  String get remoteControlDropCupOut;

  /// No description provided for @remoteControlDropCacheDiscard.
  ///
  /// In zh, this message translates to:
  /// **'缓存位'**
  String get remoteControlDropCacheDiscard;

  /// No description provided for @remoteControlCache1.
  ///
  /// In zh, this message translates to:
  /// **'缓存1'**
  String get remoteControlCache1;

  /// No description provided for @remoteControlCache2.
  ///
  /// In zh, this message translates to:
  /// **'缓存2'**
  String get remoteControlCache2;

  /// No description provided for @remoteControlCache3.
  ///
  /// In zh, this message translates to:
  /// **'缓存3'**
  String get remoteControlCache3;

  /// No description provided for @remoteControlCache4.
  ///
  /// In zh, this message translates to:
  /// **'缓存4'**
  String get remoteControlCache4;

  /// No description provided for @remoteControlCacheN.
  ///
  /// In zh, this message translates to:
  /// **'缓存{n}'**
  String remoteControlCacheN(int n);

  /// No description provided for @remoteControlCleanDoor.
  ///
  /// In zh, this message translates to:
  /// **'清理门号'**
  String get remoteControlCleanDoor;

  /// No description provided for @remoteControlCleanCache.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存位'**
  String get remoteControlCleanCache;

  /// No description provided for @remoteControlCleanCacheNone.
  ///
  /// In zh, this message translates to:
  /// **'不限缓存'**
  String get remoteControlCleanCacheNone;

  /// No description provided for @remoteControlReasonNotController.
  ///
  /// In zh, this message translates to:
  /// **'非当前控制者'**
  String get remoteControlReasonNotController;

  /// No description provided for @remoteControlReasonOccupied.
  ///
  /// In zh, this message translates to:
  /// **'控制权已被占用'**
  String get remoteControlReasonOccupied;

  /// No description provided for @remoteControlReasonInvalidParams.
  ///
  /// In zh, this message translates to:
  /// **'参数无效'**
  String get remoteControlReasonInvalidParams;

  /// No description provided for @remoteControlReasonSlaveNoResponse.
  ///
  /// In zh, this message translates to:
  /// **'下位机无响应'**
  String get remoteControlReasonSlaveNoResponse;

  /// No description provided for @remoteControlReasonUnknownCmd.
  ///
  /// In zh, this message translates to:
  /// **'未知指令'**
  String get remoteControlReasonUnknownCmd;

  /// No description provided for @remoteControlReasonAckTimeout.
  ///
  /// In zh, this message translates to:
  /// **'指令超时无响应'**
  String get remoteControlReasonAckTimeout;

  /// No description provided for @remoteControlForceRelease.
  ///
  /// In zh, this message translates to:
  /// **'强制释放'**
  String get remoteControlForceRelease;

  /// No description provided for @remoteControlQueryControl.
  ///
  /// In zh, this message translates to:
  /// **'查询控制权'**
  String get remoteControlQueryControl;

  /// No description provided for @remoteControlControllerLabel.
  ///
  /// In zh, this message translates to:
  /// **'控制者: {cId}'**
  String remoteControlControllerLabel(String cId);

  /// No description provided for @remoteControlViewersLabel.
  ///
  /// In zh, this message translates to:
  /// **'查看者: {cIds}'**
  String remoteControlViewersLabel(String cIds);

  /// No description provided for @remoteControlCupMotorOpen.
  ///
  /// In zh, this message translates to:
  /// **'杯托开'**
  String get remoteControlCupMotorOpen;

  /// No description provided for @remoteControlCupMotorClose.
  ///
  /// In zh, this message translates to:
  /// **'杯托关'**
  String get remoteControlCupMotorClose;

  /// No description provided for @remoteControlFrontDoorOpen.
  ///
  /// In zh, this message translates to:
  /// **'前门开'**
  String get remoteControlFrontDoorOpen;

  /// No description provided for @remoteControlFrontDoorClose.
  ///
  /// In zh, this message translates to:
  /// **'前门关'**
  String get remoteControlFrontDoorClose;

  /// No description provided for @remoteControlCoffeeMachine.
  ///
  /// In zh, this message translates to:
  /// **'机{n}'**
  String remoteControlCoffeeMachine(int n);

  /// No description provided for @remoteControlMqttOn.
  ///
  /// In zh, this message translates to:
  /// **'本机MQTT已连'**
  String get remoteControlMqttOn;

  /// No description provided for @remoteControlMqttOff.
  ///
  /// In zh, this message translates to:
  /// **'本机MQTT未连'**
  String get remoteControlMqttOff;

  /// No description provided for @remoteControlRelayAllOn.
  ///
  /// In zh, this message translates to:
  /// **'全开'**
  String get remoteControlRelayAllOn;

  /// No description provided for @remoteControlRelayAllOff.
  ///
  /// In zh, this message translates to:
  /// **'全关'**
  String get remoteControlRelayAllOff;

  /// No description provided for @remoteControlRelayTableFan.
  ///
  /// In zh, this message translates to:
  /// **'底仓通风'**
  String get remoteControlRelayTableFan;

  /// No description provided for @remoteControlRelayCoffeePower.
  ///
  /// In zh, this message translates to:
  /// **'咖啡机电源'**
  String get remoteControlRelayCoffeePower;

  /// No description provided for @remoteControlRelayIcePower.
  ///
  /// In zh, this message translates to:
  /// **'制冰机电源'**
  String get remoteControlRelayIcePower;

  /// No description provided for @remoteControlRelayRobotPower.
  ///
  /// In zh, this message translates to:
  /// **'机械臂电源'**
  String get remoteControlRelayRobotPower;

  /// No description provided for @remoteControlRelayAirPower.
  ///
  /// In zh, this message translates to:
  /// **'空调电源'**
  String get remoteControlRelayAirPower;

  /// No description provided for @remoteControlRelayLightPower.
  ///
  /// In zh, this message translates to:
  /// **'照明'**
  String get remoteControlRelayLightPower;

  /// No description provided for @remoteControlRelayAdPower.
  ///
  /// In zh, this message translates to:
  /// **'信息屏'**
  String get remoteControlRelayAdPower;

  /// No description provided for @remoteControlRelayBubblePower.
  ///
  /// In zh, this message translates to:
  /// **'气泡机电源'**
  String get remoteControlRelayBubblePower;

  /// No description provided for @remoteControlRelayWaterPumpIn.
  ///
  /// In zh, this message translates to:
  /// **'供水泵'**
  String get remoteControlRelayWaterPumpIn;

  /// No description provided for @remoteControlRelayWaterPumpOut.
  ///
  /// In zh, this message translates to:
  /// **'排水泵'**
  String get remoteControlRelayWaterPumpOut;

  /// No description provided for @remoteControlRelayValve1.
  ///
  /// In zh, this message translates to:
  /// **'进水阀1'**
  String get remoteControlRelayValve1;

  /// No description provided for @remoteControlRelayValve2.
  ///
  /// In zh, this message translates to:
  /// **'进水阀2'**
  String get remoteControlRelayValve2;

  /// No description provided for @remoteControlRelayValve3.
  ///
  /// In zh, this message translates to:
  /// **'进水阀3'**
  String get remoteControlRelayValve3;

  /// No description provided for @remoteControlRelayJuiceFan.
  ///
  /// In zh, this message translates to:
  /// **'果汁散热风扇'**
  String get remoteControlRelayJuiceFan;

  /// No description provided for @remoteControlRelayWaterWaste.
  ///
  /// In zh, this message translates to:
  /// **'排废水阀'**
  String get remoteControlRelayWaterWaste;

  /// No description provided for @remoteControlRelayDxkw.
  ///
  /// In zh, this message translates to:
  /// **'电伴热'**
  String get remoteControlRelayDxkw;

  /// No description provided for @remoteControlRelayLightColor.
  ///
  /// In zh, this message translates to:
  /// **'七彩灯'**
  String get remoteControlRelayLightColor;

  /// No description provided for @remoteControlSensorVoltage.
  ///
  /// In zh, this message translates to:
  /// **'电压'**
  String get remoteControlSensorVoltage;

  /// No description provided for @remoteControlSensorCurrent.
  ///
  /// In zh, this message translates to:
  /// **'电流'**
  String get remoteControlSensorCurrent;

  /// No description provided for @remoteControlSensorPower.
  ///
  /// In zh, this message translates to:
  /// **'功率'**
  String get remoteControlSensorPower;

  /// No description provided for @remoteControlSensorBottomTemp.
  ///
  /// In zh, this message translates to:
  /// **'底仓温度'**
  String get remoteControlSensorBottomTemp;

  /// No description provided for @remoteControlSensorTopTemp.
  ///
  /// In zh, this message translates to:
  /// **'上仓温度'**
  String get remoteControlSensorTopTemp;

  /// No description provided for @remoteControlSensorColdTemp.
  ///
  /// In zh, this message translates to:
  /// **'冷水温度'**
  String get remoteControlSensorColdTemp;

  /// No description provided for @remoteControlSensorIceTemp.
  ///
  /// In zh, this message translates to:
  /// **'冰藏温度'**
  String get remoteControlSensorIceTemp;

  /// No description provided for @remoteControlSensorWaterUsage.
  ///
  /// In zh, this message translates to:
  /// **'用水量'**
  String get remoteControlSensorWaterUsage;

  /// No description provided for @remoteControlSensorWaterPressure.
  ///
  /// In zh, this message translates to:
  /// **'水压'**
  String get remoteControlSensorWaterPressure;

  /// No description provided for @remoteControlSensorTDS.
  ///
  /// In zh, this message translates to:
  /// **'TDS'**
  String get remoteControlSensorTDS;

  /// No description provided for @remoteControlSensorWaterShortage.
  ///
  /// In zh, this message translates to:
  /// **'缺水'**
  String get remoteControlSensorWaterShortage;

  /// No description provided for @remoteControlDoor1.
  ///
  /// In zh, this message translates to:
  /// **'门1'**
  String get remoteControlDoor1;

  /// No description provided for @remoteControlDoor2.
  ///
  /// In zh, this message translates to:
  /// **'门2'**
  String get remoteControlDoor2;

  /// No description provided for @remoteControlDoor3.
  ///
  /// In zh, this message translates to:
  /// **'门3'**
  String get remoteControlDoor3;

  /// No description provided for @remoteControlDoor4.
  ///
  /// In zh, this message translates to:
  /// **'门4'**
  String get remoteControlDoor4;

  /// No description provided for @remoteControlCupPos1.
  ///
  /// In zh, this message translates to:
  /// **'落杯位1'**
  String get remoteControlCupPos1;

  /// No description provided for @remoteControlCupPos2.
  ///
  /// In zh, this message translates to:
  /// **'落杯位2'**
  String get remoteControlCupPos2;

  /// No description provided for @remoteControlLidPos1.
  ///
  /// In zh, this message translates to:
  /// **'落盖位1'**
  String get remoteControlLidPos1;

  /// No description provided for @remoteControlLidPos2.
  ///
  /// In zh, this message translates to:
  /// **'落盖位2'**
  String get remoteControlLidPos2;

  /// No description provided for @remoteControlCupLidCup.
  ///
  /// In zh, this message translates to:
  /// **'杯位'**
  String get remoteControlCupLidCup;

  /// No description provided for @remoteControlCupLidLid.
  ///
  /// In zh, this message translates to:
  /// **'盖位'**
  String get remoteControlCupLidLid;

  /// No description provided for @remoteControlCupLidPresent.
  ///
  /// In zh, this message translates to:
  /// **'在位'**
  String get remoteControlCupLidPresent;

  /// No description provided for @remoteControlCupLidEmpty.
  ///
  /// In zh, this message translates to:
  /// **'缺料'**
  String get remoteControlCupLidEmpty;

  /// No description provided for @remoteControlCupLidFault.
  ///
  /// In zh, this message translates to:
  /// **'故障'**
  String get remoteControlCupLidFault;

  /// No description provided for @remoteControlStockCups.
  ///
  /// In zh, this message translates to:
  /// **'杯子余量'**
  String get remoteControlStockCups;

  /// No description provided for @remoteControlStockLids.
  ///
  /// In zh, this message translates to:
  /// **'杯盖余量'**
  String get remoteControlStockLids;

  /// No description provided for @remoteControlStockJuice.
  ///
  /// In zh, this message translates to:
  /// **'果汁余量'**
  String get remoteControlStockJuice;

  /// No description provided for @remoteControlStockWater.
  ///
  /// In zh, this message translates to:
  /// **'水桶余量'**
  String get remoteControlStockWater;

  /// No description provided for @remoteControlStockJuiceChannel.
  ///
  /// In zh, this message translates to:
  /// **'管路{ch}'**
  String remoteControlStockJuiceChannel(Object ch);

  /// No description provided for @remoteControlBubble.
  ///
  /// In zh, this message translates to:
  /// **'气泡机'**
  String get remoteControlBubble;

  /// No description provided for @remoteControlJuice.
  ///
  /// In zh, this message translates to:
  /// **'果汁机'**
  String get remoteControlJuice;

  /// No description provided for @remoteControlWaterHot.
  ///
  /// In zh, this message translates to:
  /// **'热水'**
  String get remoteControlWaterHot;

  /// No description provided for @remoteControlDrop.
  ///
  /// In zh, this message translates to:
  /// **'丢杯口'**
  String get remoteControlDrop;

  /// No description provided for @remoteControlOrderFlow.
  ///
  /// In zh, this message translates to:
  /// **'订单流程'**
  String get remoteControlOrderFlow;

  /// No description provided for @remoteControlCache.
  ///
  /// In zh, this message translates to:
  /// **'缓存位'**
  String get remoteControlCache;

  /// No description provided for @remoteControlDoorOrder.
  ///
  /// In zh, this message translates to:
  /// **'出餐门订单'**
  String get remoteControlDoorOrder;

  /// No description provided for @remoteControlModuleLink.
  ///
  /// In zh, this message translates to:
  /// **'模块通讯'**
  String get remoteControlModuleLink;

  /// No description provided for @remoteControlModuleOnline.
  ///
  /// In zh, this message translates to:
  /// **'{n}/{total} 在线'**
  String remoteControlModuleOnline(Object n, Object total);

  /// No description provided for @pushFaultAlertTitle.
  ///
  /// In zh, this message translates to:
  /// **'[故障]'**
  String get pushFaultAlertTitle;

  /// No description provided for @pushWarningAlertTitle.
  ///
  /// In zh, this message translates to:
  /// **'[告警]'**
  String get pushWarningAlertTitle;

  /// No description provided for @pushStockOutAlertTitle.
  ///
  /// In zh, this message translates to:
  /// **'[缺货]'**
  String get pushStockOutAlertTitle;

  /// No description provided for @pushAlertResolvedTitle.
  ///
  /// In zh, this message translates to:
  /// **'[已恢复]'**
  String get pushAlertResolvedTitle;

  /// 通知权限永久拒绝时的提示
  ///
  /// In zh, this message translates to:
  /// **'通知权限已被永久拒绝'**
  String get pushNotificationPermissionDenied;

  /// 引导用户前往系统设置的提示
  ///
  /// In zh, this message translates to:
  /// **'请前往系统设置开启通知权限'**
  String get pushNotificationPermissionGuide;

  /// 打开系统设置按钮
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get pushNotificationPermissionOpenSettings;

  /// 网络超时错误提示
  ///
  /// In zh, this message translates to:
  /// **'网络连接超时，请检查网络设置'**
  String get networkTimeout;

  /// 网络证书错误提示
  ///
  /// In zh, this message translates to:
  /// **'网络证书校验失败'**
  String get networkBadCertificate;

  /// HTTP 400 错误提示
  ///
  /// In zh, this message translates to:
  /// **'错误的请求 (400)'**
  String get networkError400;

  /// HTTP 401 错误提示
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get networkError401;

  /// HTTP 403 错误提示
  ///
  /// In zh, this message translates to:
  /// **'拒绝访问 (403)'**
  String get networkError403;

  /// HTTP 404 错误提示
  ///
  /// In zh, this message translates to:
  /// **'请求资源不存在 (404)'**
  String get networkError404;

  /// HTTP 500 错误提示
  ///
  /// In zh, this message translates to:
  /// **'服务器内部错误 (500)'**
  String get networkError500;

  /// HTTP 502 错误提示
  ///
  /// In zh, this message translates to:
  /// **'服务器正在维护或网关错误 (502)'**
  String get networkError502;

  /// HTTP 503 错误提示
  ///
  /// In zh, this message translates to:
  /// **'服务暂时不可用 (503)'**
  String get networkError503;

  /// HTTP 其他错误提示
  ///
  /// In zh, this message translates to:
  /// **'服务器响应异常 ({code})'**
  String networkErrorDefault(int code);

  /// 请求取消提示
  ///
  /// In zh, this message translates to:
  /// **'请求已取消'**
  String get networkRequestCancelled;

  /// 连接错误提示
  ///
  /// In zh, this message translates to:
  /// **'无法连接到服务器，请检查网络'**
  String get networkConnectionError;

  /// Socket 错误提示
  ///
  /// In zh, this message translates to:
  /// **'网络不可用，请检查连接'**
  String get networkSocketError;

  /// 未知网络错误提示
  ///
  /// In zh, this message translates to:
  /// **'未知网络错误'**
  String get networkUnknownError;

  /// 网络请求失败提示
  ///
  /// In zh, this message translates to:
  /// **'网络请求失败，请稍后重试'**
  String get networkRequestFailed;

  /// 登录过期提示
  ///
  /// In zh, this message translates to:
  /// **'登录已过期，请重新登录'**
  String get authExpired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
