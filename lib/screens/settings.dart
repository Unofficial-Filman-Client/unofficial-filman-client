import "dart:io";

import "package:bonsoir/bonsoir.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BonsoirDiscovery discovery =
      BonsoirDiscovery(type: "_majusssfilman._tcp");
  final List<ResolvedBonsoirService> services = [];

  void connectToServer(final String ip) async {
    final socket = await Socket.connect(ip, 3031);

    socket.write("GETSTATE");

    socket.listen((final raw) {
      final data = String.fromCharCodes(raw).trim();
      switch (data) {
        case "STATE:LoginState.waiting":
          final login =
              Provider.of<FilmanNotifier>(context, listen: false).user?.login;
          final cookies = Provider.of<FilmanNotifier>(context, listen: false)
              .cookies
              .join(",");
          if (login == null) {
            return;
          }
          socket.write("LOGIN:$login|$cookies");
          socket.close();
          break;
        case "STATE:LoginState.done":
          discovery.stop();
          break;
      }
    });
  }

  void setupmDNS() async {
    await discovery.ready;

    discovery.eventStream?.listen((final event) async {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        if (event.isServiceResolved &&
            (event.service as ResolvedBonsoirService).host != null) {
          services.removeWhere((final service) =>
              service.host == (event.service as ResolvedBonsoirService).host);

          services.add(event.service as ResolvedBonsoirService);
          setState(() {});
        }
      } else if (event.type ==
          BonsoirDiscoveryEventType.discoveryServiceFound) {
        event.service!.resolve(discovery.serviceResolver);
      }
    });

    await discovery.start();
  }

  @override
  void initState() {
    super.initState();
    setupmDNS();
  }

  @override
  void dispose() {
    discovery.stop();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final TitleDisplayType? titleType =
        Provider.of<SettingsNotifier>(context).titleDisplayType;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ustawienia"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Tryb ciemny"),
            onTap: () {
              Provider.of<SettingsNotifier>(context, listen: false).setTheme(
                  Theme.of(context).brightness == Brightness.light
                      ? ThemeMode.dark
                      : ThemeMode.light);
            },
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (final bool value) {
                Provider.of<SettingsNotifier>(context, listen: false)
                    .setTheme(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text("Wyświetlanie tytułów"),
            subtitle: Text(
                "Tytuły na filamn.cc są dzielone '/' na człony, w zależności od języka. Wybierz, które tytuły chcesz wyświetlać:"),
          ),
          RadioListTile<TitleDisplayType>(
            title: const Text("Cały tytuł"),
            value: TitleDisplayType.all,
            groupValue: titleType,
            onChanged: (final TitleDisplayType? value) {
              Provider.of<SettingsNotifier>(context, listen: false)
                  .setTitleDisplayType(value);
            },
          ),
          RadioListTile<TitleDisplayType>(
            title: const Text("Pierwszy człon tytułu"),
            value: TitleDisplayType.first,
            groupValue: titleType,
            onChanged: (final TitleDisplayType? value) {
              Provider.of<SettingsNotifier>(context, listen: false)
                  .setTitleDisplayType(value);
            },
          ),
          RadioListTile<TitleDisplayType>(
            title: const Text("Drugi człon tytułu"),
            value: TitleDisplayType.second,
            groupValue: titleType,
            onChanged: (final TitleDisplayType? value) {
              Provider.of<SettingsNotifier>(context, listen: false)
                  .setTitleDisplayType(value);
            },
          ),
          Consumer<SettingsNotifier>(
              builder: (final context, final settings, final child) => ListTile(
                      subtitle: RichText(
                          text: TextSpan(
                    children: [
                      TextSpan(
                          text: "Przykładowy tytuł: ",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          text: getDisplayTitle(
                              "Szybcy i wściekli / The Fast and the Furious",
                              settings))
                    ],
                  )))),
          const Divider(),
          ListTile(
            title: const Text("Automatyczny wybór języka"),
            subtitle: const Text(
                "Kolejność w jakiej odtwarzacz będzie preferował języki."),
            onTap: () => Provider.of<SettingsNotifier>(context, listen: false)
                .setAutoLanguage(
                    !Provider.of<SettingsNotifier>(context, listen: false)
                        .autoLanguage),
            trailing: Switch(
              value: Provider.of<SettingsNotifier>(context, listen: false)
                  .autoLanguage,
              onChanged: (final bool value) {
                Provider.of<SettingsNotifier>(context, listen: false)
                    .setAutoLanguage(value);
              },
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (final context) => const ReorderLanguageScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Zmień kolejność języków"),
                    Icon(Icons.arrow_right)
                  ]),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text("Logowanie TV"),
            subtitle: Text("Zaloguj się na każdym telewizorze w siec WiFi."),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilledButton(
                onPressed: services.isNotEmpty
                    ? () async {
                        for (final service in services) {
                          connectToServer(service.host!);
                        }
                      }
                    : null,
                child: Text(services.isNotEmpty
                    ? "Zaloguj się na TV"
                    : "Nie znaleziono urządzeń")),
          )
        ],
      ),
    );
  }
}

class ReorderLanguageScreen extends StatelessWidget {
  const ReorderLanguageScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    final List<Language> languages =
        Provider.of<SettingsNotifier>(context).preferredLanguages;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kolejność języków"),
      ),
      body: StatefulBuilder(
          builder: (final context, final setState) => ReorderableListView(
              onReorder: (final int oldIndex, final int newIndex) {
                setState(() {
                  int delta = newIndex;
                  if (oldIndex < newIndex) {
                    delta -= 1;
                  }
                  final item = languages.removeAt(oldIndex);
                  languages.insert(delta, item);
                  Provider.of<SettingsNotifier>(context, listen: false)
                      .setPreferredLanguages(languages);
                });
              },
              children: languages
                  .map((final lang) => ListTile(
                        key: ValueKey(lang),
                        title: Text(lang.toString()),
                        trailing: const Icon(Icons.drag_handle),
                      ))
                  .toList())),
    );
  }
}
