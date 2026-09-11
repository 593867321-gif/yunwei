import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:itwo_flutter_base/itwo_base_config.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/Const.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/mqtt_manager.dart';
import 'package:operation/page/page_home.dart';
import 'package:operation/page/page_login.dart';
import 'package:operation/platform/platform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:dio/dio.dart';

import 'net/request_server.dart';
import 'services/push_service.dart';

void main() {
  if (!kIsWeb) {
    SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light);
    SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
  }
  WidgetsFlutterBinding.ensureInitialized();
  PushService.instance.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  // final APPCacheConfigBean cacheConfigBean;
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final RouterUtil routeObserver = RouterUtil.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 监听 App 前后台切换，回到前台时检查 MQTT 连接
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MqttManager.instance.checkAndReconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    APP.initConfig(context);
    APP.initJobConfig();
    ConcurrencyManager.instance.maxCount = 5;
    return MaterialApp(
      initialRoute: "/",
      onGenerateRoute: null,
      onUnknownRoute: null,
      onGenerateTitle: (context) => "Youdake",
      title: 'Youdake',
      darkTheme: ThemeData(
        platform: TargetPlatform.iOS,
        brightness: Brightness.dark,
        badgeTheme: BadgeThemeData(backgroundColor: MyColors.BACK_GROUND),
        primarySwatch: Colors.blue,
        colorScheme: const ColorScheme.dark(primary: Colors.blueGrey, secondary: Colors.blueGrey),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF333333.toInt())),
          titleMedium: TextStyle(fontSize: 14, color: Color(0xFF333333.toInt())),
        ),
        textSelectionTheme: TextSelectionThemeData(cursorColor: Color(0xFF333333.toInt())),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      ),
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        badgeTheme: BadgeThemeData(backgroundColor: MyColors.BACK_GROUND),
        colorScheme: const ColorScheme.light(primary: Colors.blueGrey, secondary: Colors.blueGrey),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF333333.toInt())),
          titleMedium: TextStyle(fontSize: 14, color: Color(0xFF333333.toInt())),
        ),
        textSelectionTheme: TextSelectionThemeData(cursorColor: Color(0xFF333333.toInt())),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.white),
      ),
      themeMode: ThemeMode.light,
      localizationsDelegates: const [AppLocalizations.delegate, RefreshLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalMaterialLocalizations.delegate, _FallbackCupertinoLocalisationsDelegate()],
      locale: const Locale("zh"),
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) => locale,
      debugShowCheckedModeBanner: true,
      home: FutureBuilder(builder: (BuildContext context, AsyncSnapshot<bool?> hot) => hot.data == true ? const HomePage(false) : const LoginPage(), future: LoginCache.isLogin()),
      // home: RouterUtil.initRouter(widget.cacheConfigBean.token.isNullOrEmpty ? const LoginPage(true) : const HomePage(true)),
      // home: LoginPage(),
      navigatorKey: RouterUtil.navigatorKey,
      navigatorObservers: [routeObserver],
      builder: EasyLoading.init(
        builder: (context, widget) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: widget ?? Container(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _incrementCounter, tooltip: 'Increment', child: const Icon(Icons.add)),
    );
  }
}

class _FallbackCupertinoLocalisationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_FallbackCupertinoLocalisationsDelegate old) => false;
}

class APP {
  APP._();

  static Future<void> initConfig(BuildContext context) async {
    Config.toast = (s) => Fluttertoast.showToast(msg: s);

    String rootPath = (await getApplicationDocumentsDirectory()).path;
    var dateStr = DateTime.now().format("yyyy-MM-dd");
    if (!kIsWeb) Config.logFile = createFile('$rootPath/$dateStr.log');
  }

  static void initJobConfig() {
    JobConfig.setParser((e) {
      if (e is DioException) {
        return e.toHumanMessage(); // 这里调用主项目的扩展逻辑
      }
      // 处理其他异常
      if (e is TypeError) return "数据类型转换错误";
      return null; // 返回 null 则 jobIO 会回退使用 toString()
    });
  }
}
