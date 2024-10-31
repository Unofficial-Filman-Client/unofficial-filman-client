import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/material.dart";
import "package:bonsoir/bonsoir.dart";
import "dart:io";

import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/main.dart";

enum LoginState { waiting, loginin, done }

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  LoginState state = LoginState.waiting;
  String status = "Otwórz aplikację na telefonie";
  late final BonsoirBroadcast broadcast;

  @override
  void initState() {
    super.initState();
    setupLogin();
  }

  @override
  void dispose() {
    super.dispose();
    broadcast.stop();
  }

  void setupLogin() async {
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
          client.write("STATE:${state.toString()}");
          return;
        }
        if (data.startsWith("LOGIN:")) {
          final [login, cookies] = data.split(":")[1].split("|");
          final filmanNotifier =
              Provider.of<FilmanNotifier>(context, listen: false);
          setState(() {
            state = LoginState.loginin;
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
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Unofficial Filman Client for TVs"),
              Text("cos tam")
            ],
          ),
          const SizedBox(
            width: 24,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [const Text("Status"), Text(status)],
          ),
        ],
      ),
    ));
  }
}
