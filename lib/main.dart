import 'package:dynamic_color/dynamic_color.dart';
import 'package:filman_flutter/notifiers/settings.dart';
import 'package:filman_flutter/notifiers/watched.dart';
import 'package:filman_flutter/screens/hello.dart';
import 'package:filman_flutter/screens/home.dart';
import 'package:filman_flutter/notifiers/filman.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final cookies = prefs.getStringList('cookies') ?? [];

  final filman = FilmanNotifier();
  final settings = SettingsNotifier();
  final watched = WatchedNotifier();

  await filman.initPrefs();
  await settings.loadSettings();
  await watched.loadWatched();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => filman),
        ChangeNotifierProvider(create: (_) => settings),
        ChangeNotifierProvider(create: (_) => watched),
      ],
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
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
        home: isAuth ? const HomeScreen() : const HelloScreen(),
      );
    });
  }
}
