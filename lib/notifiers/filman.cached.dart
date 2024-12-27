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

  @override
  Future<FilmDetails> getFilmDetails(String link) async {
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

      return toReturn;
    } else {
      return cachedValue;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
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

      return toReturn;
    } else {
      return cachedValue;
    }
  }
}
