import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecg_analyzer/Screens/homeScreen.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Utils/I18n.dart';
import 'Utils/TranslationLoader.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TranslationLoader.loadTranslations();
  // remove vivisble status bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlutterSizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.lightBlue,
          ),
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: I18n.supportedLocales,
        home: SafeArea(child: HomeScreen()),
      );
    });
  }
}
