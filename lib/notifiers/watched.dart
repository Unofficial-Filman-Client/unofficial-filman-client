import 'dart:convert';

import 'package:filman_flutter/types/watched.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchedNotifier extends ChangeNotifier {
  final List<WatchedSerial> _serials = [];
  final List<WatchedSingle> _films = [];

  List<WatchedSerial> get serials => _serials;
  List<WatchedSingle> get films => _films;

  SharedPreferences? prefs;

  Future loadWatched() async {
    prefs = await SharedPreferences.getInstance();
    final watchedSerials = prefs?.getStringList('watchedSerials');
    final watchedFilms = prefs?.getStringList('watchedFilms');
    if (watchedSerials != null) {
      _serials.addAll(
        watchedSerials
            .map((e) => WatchedSerial.fromJSON(jsonDecode(e)))
            .toList(),
      );
    }
    if (watchedFilms != null) {
      _films.addAll(
        watchedFilms.map((e) => WatchedSingle.fromJSON(jsonDecode(e))).toList(),
      );
    }

    notifyListeners();
  }

  void watch(WatchedSingle watchedSingle) {
    WatchedSingle? found = _films.firstWhereOrNull(
      (WatchedSingle film) =>
          film.filmDetails.title == watchedSingle.filmDetails.title,
    );
    if (found != null) {
      found.watching(watchedSingle.watchedInSec);
    } else {
      _films.add(watchedSingle);
    }

    prefs?.setStringList(
      'watchedFilms',
      _films.map((e) => jsonEncode(e.toMap())).toList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void watchEpisode(WatchedSerial watchedSerial, WatchedSingle watchedSingle) {
    WatchedSerial? found = _serials.firstWhereOrNull(
      (WatchedSerial serial) =>
          serial.filmDetails.title == watchedSerial.filmDetails.title,
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
      'watchedSerials',
      _serials.map((e) => jsonEncode(e.toMap())).toList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  void remove(WatchedSingle watched) {
    if (watched.parentSeason != null) {
      _serials.removeWhere(
          (serial) => serial.filmDetails.url == watched.filmDetails.parentUrl);
    } else {
      _films.removeWhere(
          (film) => film.filmDetails.url == watched.filmDetails.url);
    }
  }
}
