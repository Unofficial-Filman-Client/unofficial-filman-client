import "dart:convert";

import "package:unofficial_filman_client/types/watched.dart";
import "package:flutter/material.dart";
import "package:collection/collection.dart";
import "package:shared_preferences/shared_preferences.dart";

class WatchedNotifier extends ChangeNotifier {
  final List<WatchedSerial> _serials = [];
  final List<WatchedSingle> _films = [];

  List<WatchedSerial> get serials => _serials;
  List<WatchedSingle> get films => _films;

  SharedPreferences? prefs;

  Future loadWatched() async {
    prefs = await SharedPreferences.getInstance();
    final watchedSerials = prefs?.getStringList("watchedSerials");
    final watchedFilms = prefs?.getStringList("watchedFilms");
    if (watchedSerials != null) {
      _serials.addAll(
        watchedSerials
            .map((final e) => WatchedSerial.fromMap(jsonDecode(e)))
            .toList(),
      );
    }
    if (watchedFilms != null) {
      _films.addAll(
        watchedFilms.map((final e) => WatchedSingle.fromMap(jsonDecode(e))).toList(),
      );
    }

    notifyListeners();
  }

  void watch(final WatchedSingle watchedSingle) {
    final WatchedSingle? found = _films.firstWhereOrNull(
      (final WatchedSingle film) =>
          film.filmDetails.url == watchedSingle.filmDetails.url,
    );
    if (found != null) {
      found.watching(watchedSingle.watchedInSec);
    } else {
      _films.add(watchedSingle);
    }

    prefs?.setStringList(
      "watchedFilms",
      _films.map((final e) => jsonEncode(e.toMap())).toList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((final _) => notifyListeners());
  }

  void watchEpisode(final WatchedSerial watchedSerial, final WatchedSingle watchedSingle) {
    final WatchedSerial? found = _serials.firstWhereOrNull(
      (final serial) => serial.filmDetails.url == watchedSerial.filmDetails.url,
    );
    if (found != null) {
      found.watching(watchedSingle);
    } else {
      _serials.add(
        WatchedSerial(
          filmDetails: watchedSerial.filmDetails,
          episodes: [watchedSingle],
          lastWatched: watchedSingle,
          watchedAt: DateTime.now(),
        ),
      );
    }

    prefs?.setStringList(
      "watchedSerials",
      _serials.map((final e) => jsonEncode(e.toMap())).toList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((final _) => notifyListeners());
  }

  void remove(final WatchedSingle watched) {
    if (watched.parentSeason != null) {
      _serials.removeWhere(
          (final serial) => serial.filmDetails.url == watched.filmDetails.parentUrl);
      prefs?.setStringList(
        "watchedSerials",
        _serials.map((final e) => jsonEncode(e.toMap())).toList(),
      );
    } else {
      _films.removeWhere(
          (final film) => film.filmDetails.url == watched.filmDetails.url);
      prefs?.setStringList(
        "watchedFilms",
        _films.map((final e) => jsonEncode(e.toMap())).toList(),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((final _) => notifyListeners());
  }
}
