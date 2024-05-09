import 'package:dynamic_color/dynamic_color.dart';
import 'package:filman_flutter/screens/home.dart';
import 'package:filman_flutter/screens/login.dart';
import 'package:filman_flutter/model.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final cookies = prefs.getStringList('cookies') ?? [];

  final filman = FilmanModel();
  await filman.initPrefs();
  runApp(
    ChangeNotifierProvider(
      create: (context) => filman,
      child: MyApp(
        isAuth: cookies.isNotEmpty,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isAuth;

  const MyApp({super.key, this.isAuth = false});

  static final _defaultLightColorScheme =
      ColorScheme.fromSwatch(primarySwatch: Colors.blue);

  static final _defaultDarkColorScheme = ColorScheme.fromSwatch(
      primarySwatch: Colors.blue, brightness: Brightness.dark);

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'Unofficial Filman.cc App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: lightColorScheme ?? _defaultLightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: isAuth ? const HomeScreen() : const LoginScreen(),
      );
    });
  }
}
