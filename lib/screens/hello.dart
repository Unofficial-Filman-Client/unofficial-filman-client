import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/material.dart";
import "package:bonsoir/bonsoir.dart";
import "dart:io";

import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/main.dart";
import "package:unofficial_filman_client/utils/updater.dart";

enum LoginState { waiting, loginin, done }

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  
  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  LoginState _state = LoginState.waiting;
  String status =
      "Otwórz aplikacje na urządzeniu z Androidem, następnie w ustawieniach kliknij \"Zaloguj się na TV\"";
  late final BonsoirBroadcast broadcast;

  @override
  void initState() {
    super.initState();
    setupLogin();
    checkForUpdates();
  }

  @override
  void dispose() {
    super.dispose();
    broadcast.stop();
  }

  void setupLogin() async {
    if (!Platform.isAndroid) return;
    final BonsoirService service = BonsoirService(
      name: (await DeviceInfoPlugin().androidInfo).device,
      type: "_majusssfilman._tcp",
      port: 3030,
    );
    broadcast = BonsoirBroadcast(service: service);

    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 3031);
    serverSocket.listen((final client) {
      client.listen((final raw) {
        final data = String.fromCharCodes(raw).trim();
        if (data == "GETSTATE") {
          client.write("STATE:${_state.toString()}");
          return;
        }
        if (data.startsWith("LOGIN:")) {
          final [login, cookies] = data.split(":")[1].split("|");
          final filmanNotifier =
              Provider.of<FilmanNotifier>(context, listen: false);
          setState(() {
            _state = LoginState.loginin;
            status = "Logowanie jako $login...";
            filmanNotifier.cookies
              ..clear()
              ..addAll(cookies.split(","));
            filmanNotifier.prefs.setStringList("cookies", cookies.split(","));
            filmanNotifier.saveUser(login);
          });
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (final _) => const MainScreen()));
          client.write("STATE:LoginState.done");
          broadcast.stop();
        }
      });
    });

    await broadcast.ready;
    await broadcast.start();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Unofficial Filman Client for TVs",
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Flexible(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.4),
                    child: const Text(
                      "Ta nieoficjalna aplikacja, stworzona przez entuzjaste programowania, wyświetla dane z Filman.cc i innych stron internetowych firm trzecich. Nie jesteśmy związani z Filman.cc ani z żadną inną stroną internetową, którą wyświetlamy. Traktuj tę aplikację jako narzędzie do przeglądania treści.",
                    )),
              ),
            ],
          ),
          const SizedBox(
            width: 24,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Status", style: Theme.of(context).textTheme.headlineMedium),
              Flexible(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.4),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                    )),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
