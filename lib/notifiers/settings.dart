import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

enum TitleDisplayType { first, second, all }

class SettingsNotifier extends ChangeNotifier {
  TitleDisplayType? _titleType = TitleDisplayType.all;

  ThemeMode _theme = ThemeMode.system;

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
}
