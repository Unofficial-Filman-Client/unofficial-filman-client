import 'package:filman_flutter/types/film.dart';

class SearchResults {
  final List<Film> resuls = [];

  void addFilm(Film film) {
    resuls.add(film);
  }

  List<Film> getFilms() {
    return resuls;
  }

  bool isNotEmpty() {
    return resuls.isNotEmpty;
  }
}
