// ignore_for_file: deprecated_member_use

import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";

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
    final bool useCustomKeyboard =
        Provider.of<SettingsNotifier>(context).useCustomKeyboard;

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
          ListTile(
            title: const Text("Klawiatura aplikacji"),
            subtitle: const Text(
                "Jeśli masz problemy z klawiaturą systemową lub jej wygląd Ci nie odpowiada, możesz włączyć klawiaturę aplikacji."),
            trailing: Switch(
              value: useCustomKeyboard,
              onChanged: (final bool value) {
                Provider.of<SettingsNotifier>(context, listen: false)
                    .setUseCustomKeyboard(value);
              },
            ),
          ),
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
            title: Text("Wyświetlanie tytułów"),
            subtitle: Text(
                "Tytuły na filman.cc są dzielone '/' na człony, w zależności od języka. Wybierz, które tytuły chcesz wyświetlać:"),
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
        ],
      ),
    );
  }
}

class ReorderLanguageScreen extends StatefulWidget {
  const ReorderLanguageScreen({super.key});

  @override
  State<ReorderLanguageScreen> createState() => _ReorderLanguageScreenState();
}

class _ReorderLanguageScreenState extends State<ReorderLanguageScreen> {
  int _selectedIndex = 0;
  bool _isEditMode = false;
  late List<Language> _languages;

  @override
  void initState() {
    super.initState();
    _languages = List.from(
        Provider.of<SettingsNotifier>(context, listen: false).preferredLanguages);
  }

  void _moveItem(bool moveUp) {
    setState(() {
      final index = _selectedIndex;
      if (moveUp && index > 0) {
        // Move item up
        final item = _languages.removeAt(index);
        _languages.insert(index - 1, item);
        _selectedIndex = index - 1;
        _saveChanges();
      } else if (!moveUp && index < _languages.length - 1) {
        // Move item down
        final item = _languages.removeAt(index);
        _languages.insert(index + 1, item);
        _selectedIndex = index + 1;
        _saveChanges();
      }
    });
  }

  void _saveChanges() {
    Provider.of<SettingsNotifier>(context, listen: false)
        .setPreferredLanguages(_languages);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      setState(() {
        if (_isEditMode) {
          switch (event.logicalKey.keyLabel) {
            case 'Arrow Up':
              _moveItem(true);
              break;
            case 'Arrow Down':
              _moveItem(false);
              break;
            case 'Select':
            case 'Enter':
            case 'Back':
              _isEditMode = false;
              break;
          }
        } else {
          switch (event.logicalKey.keyLabel) {
            case 'Arrow Up':
              if (_selectedIndex > 0) {
                _selectedIndex--;
              }
              break;
            case 'Arrow Down':
              if (_selectedIndex < _languages.length - 1) {
                _selectedIndex++;
              }
              break;
            case 'Select':
            case 'Enter':
              _isEditMode = true;
              break;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kolejność języków"),
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: _handleKeyEvent,
        child: ListView.builder(
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedIndex;
            final isEditing = isSelected && _isEditMode;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(
                horizontal: isEditing ? 20.0 : 0.0,
                vertical: isEditing ? 10.0 : 0.0,
              ),
              decoration: BoxDecoration(
                color: isEditing
                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                    : (isSelected
                        ? Theme.of(context).focusColor
                        : Colors.transparent),
                border: Border.all(
                  color: isEditing
                      ? Theme.of(context).primaryColor
                      : (isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.5)
                          : Colors.transparent),
                  width: isEditing ? 3.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(isEditing ? 12.0 : 0.0),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: isEditing ? 8.0 : 0.0,
                ),
                title: Text(
                  _languages[index].toString(),
                  style: TextStyle(
                    fontSize: isEditing ? 22 : 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isEditing
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            size: 32,
                            color: index > 0
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 32,
                            color: index < _languages.length - 1
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}