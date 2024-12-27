import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";

enum TitleDisplayType { first, second, all }

class SettingsNotifier extends ChangeNotifier {
  TitleDisplayType? _titleType = TitleDisplayType.all;

  ThemeMode _theme = ThemeMode.system;

  bool _autoLanguage = true;
  List<Language> _preferredLanguages = Language.values.toList();

  SharedPreferences? prefs;

  Future loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    final titleDisplayType = prefs?.getString("TitleDisplayType");
    if (titleDisplayType != null) {
      _titleType = TitleDisplayType.values.firstWhere(
          (final element) => element.toString() == titleDisplayType);
    }
    final theme = prefs?.getString("Theme");
    if (theme != null) {
      _theme = ThemeMode.values.firstWhere(
          (final element) => element.toString() == theme,
          orElse: () => ThemeMode.system);
    }
    final autoLanguage = prefs?.getBool("AutoLanguage");
    if (autoLanguage != null) {
      _autoLanguage = autoLanguage;
    }
    final preferredLanguages = prefs?.getStringList("PreferredLanguages");
    if (preferredLanguages != null) {
      _preferredLanguages = preferredLanguages.map((final e) {
        return Language.values
            .firstWhere((final element) => element.toString() == e);
      }).toList();
    }
    notifyListeners();
  }

  TitleDisplayType? get titleDisplayType => _titleType;

  void setTitleDisplayType(final TitleDisplayType? value) {
    _titleType = value;
    prefs?.setString("TitleDisplayType", _titleType.toString());
    notifyListeners();
  }

  ThemeMode get theme => _theme;

  void setTheme(final ThemeMode theme) {
    _theme = theme;
    prefs?.setString("Theme", theme.toString());
    notifyListeners();
  }

  bool get autoLanguage => _autoLanguage;
  List<Language> get preferredLanguages => _preferredLanguages;

  void setAutoLanguage(final bool value) {
    _autoLanguage = value;
    prefs?.setBool("AutoLanguage", value);
    notifyListeners();
  }

  void setPreferredLanguages(final List<Language> languages) {
    _preferredLanguages = languages;
    prefs?.setStringList("PreferredLanguages",
        _preferredLanguages.map((final e) => e.toString()).toList());
    notifyListeners();
  }
}
