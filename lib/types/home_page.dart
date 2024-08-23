import "package:unofficial_filman_client/types/film.dart";

class HomePageResponse {
  final Map<String, List<Film>> _filmMap = {};
  final List<String> categories = [];

  void addFilm(final String key, final Film film) {
    if (!categories.contains(key)) {
      categories.add(key);
    }
    if (_filmMap.containsKey(key)) {
      _filmMap[key]!.add(film);
    } else {
      _filmMap[key] = [film];
    }
  }

  List<Film>? getFilms(final String key) {
    return _filmMap[key];
  }
}
