import "package:unofficial_filman_client/types/film.dart";

class SearchResults {
  final List<Film> resuls = [];

  void addFilm(final Film film) {
    resuls.add(film);
  }

  List<Film> getFilms() {
    return resuls;
  }

  bool isNotEmpty() {
    return resuls.isNotEmpty;
  }
}
