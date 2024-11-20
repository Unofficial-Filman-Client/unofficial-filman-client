import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
        ],
      ),
    );
  }
}
