import 'package:unofficial_filman_client/notifiers/settings.dart';
import 'package:unofficial_filman_client/utils/titlte.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    TitleDisplayType? titleType =
        Provider.of<SettingsNotifier>(context).titleType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Wyświetlanie tytułów'),
            subtitle: Text(
                'Tytuły na filamn.cc są dzielone \'/\' na człony, w zależności od języka. Wybierz, które tytuły chcesz wyświetlać:'),
          ),
          RadioListTile<TitleDisplayType>(
            title: const Text('Cały tytuł'),
            value: TitleDisplayType.all,
            groupValue: titleType,
            onChanged: (TitleDisplayType? value) {
              Provider.of<SettingsNotifier>(context, listen: false)
                  .setCharacter(value);
            },
          ),
          RadioListTile<TitleDisplayType>(
            title: const Text('Pierwszy człon tytułu'),
            value: TitleDisplayType.first,
            groupValue: titleType,
            onChanged: (TitleDisplayType? value) {
              Provider.of<SettingsNotifier>(context, listen: false)
                  .setCharacter(value);
            },
          ),
          RadioListTile<TitleDisplayType>(
            title: const Text('Drugi człon tytułu'),
            value: TitleDisplayType.second,
            groupValue: titleType,
            onChanged: (TitleDisplayType? value) {
              Provider.of<SettingsNotifier>(context, listen: false)
                  .setCharacter(value);
            },
          ),
          Consumer<SettingsNotifier>(
              builder: (context, settings, child) => ListTile(
                      subtitle: RichText(
                          text: TextSpan(
                    children: [
                      const TextSpan(
                          text: 'Przykładowy tytuł: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: getDisplayTitle(
                              'Szybcy i wściekli / The Fast and the Furious',
                              settings))
                    ],
                  )))),
          const Divider(),
        ],
      ),
    );
  }
}
