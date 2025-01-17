import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:media_kit/media_kit.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/hello.dart";
import "package:unofficial_filman_client/screens/main.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "package:unofficial_filman_client/utils/navigation_service.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final cookies = prefs.getStringList("cookies") ?? [];

  final filman = FilmanNotifier();
  final settings = SettingsNotifier();
  final watched = WatchedNotifier();
  final download = DownloadNotifier();

  await filman.initPrefs();
  await settings.loadSettings();
  await watched.loadWatched();
  await download.loadDownloads();

  await FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 3));

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (final _) => filman),
        ChangeNotifierProvider(create: (final _) => settings),
        ChangeNotifierProvider(create: (final _) => watched),
        ChangeNotifierProvider(create: (final _) => download),
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
  Widget build(final BuildContext context) {
    return DynamicColorBuilder(
        builder: (final lightColorScheme, final darkColorScheme) {
      return SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: MaterialApp(
            title: "Unofficial Filman.cc App",
            debugShowCheckedModeBanner: false,
            navigatorKey: NavigationService.navigatorKey,
            theme: ThemeData(
              colorScheme: lightColorScheme ?? _defaultLightColorScheme,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
              useMaterial3: true,
            ),
            themeMode: ThemeMode.dark,
            home: isAuth ? const MainScreen() : const HelloScreen(),
          ));
    });
  }
}
