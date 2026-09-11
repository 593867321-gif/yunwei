/// 平台适配：Web 使用桩文件，原生使用 dart:io
export 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';
