import 'package:flutter/material.dart';

abstract final class AppKeys {
  // ========== Login ==========
  static const loginAccountInput = ValueKey("login_account_input");
  static const loginPasswordInput = ValueKey("login_password_input");
  static const loginButton = ValueKey("login_button");

  // ========== Home ==========
  static const homeMenuInventory = ValueKey("home_menu_inventory");
  static const homeMenuScan = ValueKey("home_menu_scan");
  static const homeMenuDevices = ValueKey("home_menu_devices");
  static const homeMenuOrders = ValueKey("home_menu_orders");
  static const homeMenuRepair = ValueKey("home_menu_repair");
  static const homeMenuReport = ValueKey("home_menu_report");
  static const homeDomainLabel = ValueKey("home_domain_label");
  static const homeAlertViewAll = ValueKey("home_alert_view_all");
  static const homeNotificationBell = ValueKey("home_notification_bell");
  static const homeLogoutButton = ValueKey("home_logout_button");

  // ========== Device List ==========
  static const deviceSearchInput = ValueKey("device_search_input");
  static const deviceFilterAll = ValueKey("device_filter_all");
  static const deviceFilterOnline = ValueKey("device_filter_online");
  static const deviceFilterOffline = ValueKey("device_filter_offline");
  static const deviceBackButton = ValueKey("device_back_button");
  static const deviceDomainFilter = ValueKey("device_domain_filter");
  static Key deviceCard(int index) => ValueKey("device_card_$index");
  static Key deviceBtnStock(int index) => ValueKey("device_btn_stock_$index");
  static Key deviceBtnStatus(int index) => ValueKey("device_btn_status_$index");
  static Key deviceBtnControl(int index) => ValueKey("device_btn_control_$index");

  // ========== Stock ==========
  static const stockBackButton = ValueKey("stock_back_button");
  static const stockDomainFilter = ValueKey("stock_domain_filter");
  static const stockRecordEntry = ValueKey("stock_record_entry");
  static Key stockBtnEdit(int index) => ValueKey("stock_btn_edit_$index");
  static Key stockBtnMaterial(int index) => ValueKey("stock_btn_material_$index");
  static Key stockUndo(int index) => ValueKey("stock_undo_$index");
  static const stockSubmitBar = ValueKey("stock_submit_bar");
  static const stockSubmitBtn = ValueKey("stock_submit_btn");
  static const stockDialogInput = ValueKey("stock_dialog_input");
  static const stockModeSet = ValueKey("stock_mode_set");
  static const stockModeAdd = ValueKey("stock_mode_add");

  // ========== Stock Record ==========
  static const stockRecordTabAll = ValueKey("stock_record_tab_all");
  static const stockRecordTabPreDeduct = ValueKey("stock_record_tab_pre_deduct");
  static const stockRecordTabAdjustment = ValueKey("stock_record_tab_adjustment");
  static const stockRecordTabRollback = ValueKey("stock_record_tab_rollback");
  static const stockRecordTabRefill = ValueKey("stock_record_tab_refill");
  static const stockRecordTabWaste = ValueKey("stock_record_tab_waste");
  static const stockRecordRetry = ValueKey("stock_record_retry");

  // ========== Order List ==========
  static const orderSearchInput = ValueKey("order_search_input");
  static const orderBackButton = ValueKey("order_back_button");
  static const orderDomainFilter = ValueKey("order_domain_filter");
  static const orderDateToday = ValueKey("order_date_today");
  static const orderDate7days = ValueKey("order_date_7days");
  static const orderDate30days = ValueKey("order_date_30days");
  static const orderDateCustom = ValueKey("order_date_custom");
  static const orderStatusAll = ValueKey("order_status_all");
  static const orderStatusUnpaid = ValueKey("order_status_unpaid");
  static const orderStatusPaid = ValueKey("order_status_paid");
  static const orderStatusProcessing = ValueKey("order_status_processing");
  static const orderStatusCompleted = ValueKey("order_status_completed");
  static const orderStatusCancelled = ValueKey("order_status_cancelled");
  static const orderStatusRefunded = ValueKey("order_status_refunded");
  static Key orderCard(int index) => ValueKey("order_card_$index");

  // ========== Order Detail ==========
  static const orderDetailBackButton = ValueKey("order_detail_back_button");
  static const orderDetailCopySn = ValueKey("order_detail_copy_sn");
  static const orderDetailMore = ValueKey("order_detail_more");
  static const orderDetailMenuStockRecord = ValueKey("order_detail_menu_stock_record");
  static const orderDetailMenuRefresh = ValueKey("order_detail_menu_refresh");
  static const orderDetailBatchCancel = ValueKey("order_detail_batch_cancel");
  static Key orderDetailBtnCancel(int itemId) => ValueKey("order_detail_btn_cancel_$itemId");
  static Key orderDetailBtnForceCancel(int itemId) => ValueKey("order_detail_btn_force_cancel_$itemId");
  static Key orderDetailBtnDiscard(int itemId) => ValueKey("order_detail_btn_discard_$itemId");

  // ========== Order Item Detail ==========
  static const orderItemBackButton = ValueKey("order_item_back_button");
  static const orderItemCopyId = ValueKey("order_item_copy_id");
  static const orderItemCopySn = ValueKey("order_item_copy_sn");
  static const orderItemBtnCancel = ValueKey("order_item_btn_cancel");
  static const orderItemBtnForceCancel = ValueKey("order_item_btn_force_cancel");
  static const orderItemBtnDiscard = ValueKey("order_item_btn_discard");
  static const orderItemStockRecord = ValueKey("order_item_stock_record");

  // ========== Alert ==========
  static const alertTypeAll = ValueKey("alert_type_all");
  static const alertTypeFault = ValueKey("alert_type_fault");
  static const alertTypeWarning = ValueKey("alert_type_warning");
  static const alertTypeStockOut = ValueKey("alert_type_stock_out");
  static const alertStatusAll = ValueKey("alert_status_all");
  static const alertStatusNew = ValueKey("alert_status_new");
  static const alertStatusAcknowledged = ValueKey("alert_status_acknowledged");
  static const alertStatusResolved = ValueKey("alert_status_resolved");
  static const alertBatchAcknowledge = ValueKey("alert_batch_acknowledge");
  static const alertBatchResolve = ValueKey("alert_batch_resolve");
  static Key alertCard(int index) => ValueKey("alert_card_$index");

  // ========== Scan ==========
  static const scanBackButton = ValueKey("scan_back_button");

  // ========== Device Detail ==========
  static const deviceDetailBackButton = ValueKey("device_detail_back_button");
  static Key deviceDetailChartBtn(String metric) => ValueKey("device_detail_chart_$metric");

  // ========== Device Drawer ==========
  static const drawerSearchInput = ValueKey("drawer_search_input");
  static const drawerCloseButton = ValueKey("drawer_close_button");
  static const drawerAllDevicesItem = ValueKey("drawer_all_devices_item");

  // ========== Dialogs ==========
  static const dialogConfirmCancel = ValueKey("dialog_confirm_cancel");
  static const dialogCancel = ValueKey("dialog_cancel");
  static const dialogConfirmForceCancel = ValueKey("dialog_confirm_force_cancel");
  static const dialogRiskCheckbox = ValueKey("dialog_risk_checkbox");
  static const dialogConfirmDiscard = ValueKey("dialog_confirm_discard");
  static const dialogConfirmBatchCancel = ValueKey("dialog_confirm_batch_cancel");
  static const dialogStockConfirm = ValueKey("dialog_stock_confirm");
  static const dialogStockCancel = ValueKey("dialog_stock_cancel");
  static const dialogRefundSwitch = ValueKey("dialog_refund_switch");
  static const dialogReasonInput = ValueKey("dialog_reason_input");
}
