// 回归测试：泛型 trySingle 必须让宿主代码的扩展方法调用可用
//
// 背景（真实缺陷）：trySingle 曾被实现为 Future<dynamic>。宿主 page_home.dart 扫码分支写的是
//   var result = await trySingle(() async => ...?.take());
//   if (result.isNullOrEmpty) { ...toast(); return; }   // 弹窗在此之后
// 扩展方法（String?.isNullOrEmpty）是静态解析的：当 result 的静态类型是 dynamic 时，
// Dart 不会走扩展方法，而是当作实例 getter 查找，运行时抛 NoSuchMethodError。
// 该异常发生在无人 await 的 async 回调里被静默吞掉 → 后续弹窗代码整段不执行，
// 表现即用户反馈的「扫码后什么都不弹，直接回到首页」。

import 'package:flutter_test/flutter_test.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';

void main() {
  group('trySingle 泛型签名（扫码弹窗缺陷回归）', () {
    test('返回 String? 时可直接调用 String 扩展方法（修复前会抛 NoSuchMethodError）', () async {
      final result = await trySingle(() async => '123456');
      // 关键断言：静态类型必须是 String?，扩展方法才可用
      expect(result, isA<String?>());
      expect(result.isNullOrEmpty, isFalse);
    });

    test('task 返回 null 时 isNullOrEmpty 为 true', () async {
      final result = await trySingle<String>(() async => null);
      expect(result, isNull);
      expect(result.isNullOrEmpty, isTrue);
    });

    test('task 返回空串时 isNullOrEmpty 为 true', () async {
      final result = await trySingle(() async => '');
      expect(result.isNullOrEmpty, isTrue);
    });

    test('task 抛异常时吞掉并返回 null，不上抛', () async {
      final result = await trySingle<String>(() async => throw Exception('boom'));
      expect(result, isNull);
      expect(result.isNullOrEmpty, isTrue);
    });

    test('泛型可正确推断为 bool?（对应 page_stock.dart 提交库存的用法）', () async {
      final success = await trySingle(() async => true);
      expect(success, isA<bool?>());
      expect(success == true, isTrue);
    });

    test('泛型可正确推断为 List（对应列表类返回值）', () async {
      final list = await trySingle(() async => <int>[1, 2, 3]);
      expect(list, isA<List<int>?>());
      expect(list?.length, 3);
    });

    test('复现原始扫码分支逻辑：成功时不会提前 return，能走到弹窗', () async {
      var dialogShown = false;
      // 模拟接口成功返回秘钥
      final result = await trySingle(() async => '884823');
      if (result.isNullOrEmpty) {
        // 扫码失败分支：不应进入
        dialogShown = false;
      } else {
        // 弹窗分支：修复后必须到达
        dialogShown = true;
      }
      expect(dialogShown, isTrue, reason: '扫码成功时必须弹出「二维码秘钥」弹窗');
    });

    test('接口失败时走扫码失败分支，不弹窗', () async {
      var dialogShown = false;
      final result = await trySingle<String>(() async => null);
      if (result.isNullOrEmpty) {
        dialogShown = false;
      } else {
        dialogShown = true;
      }
      expect(dialogShown, isFalse);
    });
  });
}
