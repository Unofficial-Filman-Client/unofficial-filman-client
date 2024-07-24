import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

enum TitleDisplayType { first, second, all }

class SettingsNotifier extends ChangeNotifier {
  TitleDisplayType? _titleType = TitleDisplayType.all;
  SharedPreferences? prefs;

  Future loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    final titleDisplayType = prefs?.getString("TitleDisplayType");
    if (titleDisplayType != null) {
      _titleType = TitleDisplayType.values
          .firstWhere((final element) => element.toString() == titleDisplayType);
    }
    notifyListeners();
  }

  TitleDisplayType? get titleType => _titleType;

  void setCharacter(final TitleDisplayType? value) {
    _titleType = value;
    prefs?.setString("TitleDisplayType", _titleType.toString());
    notifyListeners();
  }
}
