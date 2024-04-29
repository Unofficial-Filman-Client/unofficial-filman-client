import 'package:filman_flutter/types/film.dart';

class HomePage {
  final Map<String, List<Film>> filmMap = {};
  final List<String> categories = [];

  void addFilm(String key, Film film) {
    if (!categories.contains(key)) {
      categories.add(key);
    }
    if (filmMap.containsKey(key)) {
      filmMap[key]!.add(film);
    } else {
      filmMap[key] = [film];
    }
  }

  List<Film>? getFilms(String key) {
    return filmMap[key];
  }

  List<String> getCategories() {
    return categories;
  }
}
