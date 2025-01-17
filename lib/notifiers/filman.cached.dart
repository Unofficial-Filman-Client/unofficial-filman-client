// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'filman.dart';

// **************************************************************************
// CachedGenerator
// **************************************************************************

abstract class _$FilmanNotifier {}

class _FilmanNotifier with FilmanNotifier implements _$FilmanNotifier {
  _FilmanNotifier();

  final _getFilmDetailsCached = <String, FilmDetails>{};
  final _getCategoriesCached = <String, List<Category>>{};
  final _getMoviesByCategoryCached = <String, List<Film>>{};

  final _getFilmDetailsTtl = <String, String>{};
  final _getCategoriesTtl = <String, String>{};
  final _getMoviesByCategoryTtl = <String, String>{};

  @override
  Future<FilmDetails> getFilmDetails(String link) async {
    final now = DateTime.now();
    final cachedTtl = _getFilmDetailsTtl["${link.hashCode}"];
    final currentTtl = cachedTtl != null ? DateTime.parse(cachedTtl) : null;

    if (currentTtl != null && currentTtl.isBefore(now)) {
      _getFilmDetailsTtl.remove("${link.hashCode}");
      _getFilmDetailsCached.remove("${link.hashCode}");
    }

    final cachedValue = _getFilmDetailsCached["${link.hashCode}"];
    if (cachedValue == null) {
      final FilmDetails toReturn;
      try {
        final result = super.getFilmDetails(link);

        toReturn = await result;
      } catch (_) {
        rethrow;
      } finally {}

      _getFilmDetailsCached["${link.hashCode}"] = toReturn;

      const duration = Duration(seconds: 30);
      _getFilmDetailsTtl["${link.hashCode}"] =
          DateTime.now().add(duration).toIso8601String();

      return toReturn;
    } else {
      return cachedValue;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    final now = DateTime.now();
    final cachedTtl = _getCategoriesTtl[""];
    final currentTtl = cachedTtl != null ? DateTime.parse(cachedTtl) : null;

    if (currentTtl != null && currentTtl.isBefore(now)) {
      _getCategoriesTtl.remove("");
      _getCategoriesCached.remove("");
    }

    final cachedValue = _getCategoriesCached[""];
    if (cachedValue == null) {
      final List<Category> toReturn;
      try {
        final result = super.getCategories();

        toReturn = await result;
      } catch (_) {
        rethrow;
      } finally {}

      _getCategoriesCached[""] = toReturn;

      const duration = Duration(seconds: 30);
      _getCategoriesTtl[""] = DateTime.now().add(duration).toIso8601String();

      return toReturn;
    } else {
      return cachedValue;
    }
  }

  @override
  Future<List<Film>> getMoviesByCategory(
      Category category, bool forSeries) async {
    final now = DateTime.now();
    final cachedTtl =
        _getMoviesByCategoryTtl["${category.hashCode}${forSeries.hashCode}"];
    final currentTtl = cachedTtl != null ? DateTime.parse(cachedTtl) : null;

    if (currentTtl != null && currentTtl.isBefore(now)) {
      _getMoviesByCategoryTtl
          .remove("${category.hashCode}${forSeries.hashCode}");
      _getMoviesByCategoryCached
          .remove("${category.hashCode}${forSeries.hashCode}");
    }

    final cachedValue =
        _getMoviesByCategoryCached["${category.hashCode}${forSeries.hashCode}"];
    if (cachedValue == null) {
      final List<Film> toReturn;
      try {
        final result = super.getMoviesByCategory(category, forSeries);

        toReturn = await result;
      } catch (_) {
        rethrow;
      } finally {}

      _getMoviesByCategoryCached["${category.hashCode}${forSeries.hashCode}"] =
          toReturn;

      const duration = Duration(seconds: 30);
      _getMoviesByCategoryTtl["${category.hashCode}${forSeries.hashCode}"] =
          DateTime.now().add(duration).toIso8601String();

      return toReturn;
    } else {
      return cachedValue;
    }
  }
}