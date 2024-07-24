import "package:collection/collection.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/season.dart";

class WatchedSingle {
  FilmDetails filmDetails;
  int watchedInSec;
  int totalInSec;
  DateTime watchedAt;
  Season? parentSeason;

  WatchedSingle(
      {required this.filmDetails,
      required this.watchedInSec,
      required this.totalInSec,
      required this.watchedAt,
      this.parentSeason});

  WatchedSingle.fromFilmDetails(
      {required final FilmDetails filmDetailsFrom,
      required final int sec,
      required final int totalSec,
      this.parentSeason})
      : filmDetails = filmDetailsFrom,
        watchedInSec = sec,
        totalInSec = totalSec,
        watchedAt = DateTime.now();

  WatchedSingle.fromMap(final Map<String, dynamic> json)
      : filmDetails = FilmDetails.fromMap(json["filmDetails"]),
        watchedInSec = json["watchedInSec"],
        totalInSec = json["totalInSec"],
        watchedAt = DateTime.parse(json["watchedAt"]),
        parentSeason = json["parentSeason"] != null
            ? Season.fromMap(json["parentSeason"])
            : null;

  void watching(final int sec) {
    watchedInSec = sec;
    watchedAt = DateTime.now();
  }

  double get watchedPercentage {
    if (totalInSec == 0) return 0.0;
    return watchedInSec / totalInSec;
  }

  Map<String, dynamic> toMap() {
    return {
      "filmDetails": filmDetails.toMap(),
      "watchedInSec": watchedInSec,
      "totalInSec": totalInSec,
      "watchedAt": watchedAt.toIso8601String(),
      "parentSeason": parentSeason?.toMap(),
    };
  }

  @override
  String toString() {
    return "WatchedSingle(filmDetails: $filmDetails, watchedInSec: $watchedInSec, totalInSec: $totalInSec, watchedAt: $watchedAt, parentSeason: $parentSeason)";
  }
}

class WatchedSerial {
  FilmDetails filmDetails;
  List<WatchedSingle> episodes;
  WatchedSingle lastWatched;
  DateTime watchedAt;

  WatchedSerial({
    required this.filmDetails,
    required this.episodes,
    required this.lastWatched,
    required this.watchedAt,
  });

  WatchedSerial.fromFilmDetails({
    required final FilmDetails filmDetailsFrom,
    required final WatchedSingle lastWatchedFromDetails,
  })  : filmDetails = filmDetailsFrom,
        episodes = [],
        lastWatched = lastWatchedFromDetails,
        watchedAt = DateTime.now();

  WatchedSerial.fromMap(final Map<String, dynamic> json)
      : filmDetails = FilmDetails.fromMap(json["filmDetails"]),
        episodes = json["episodes"] != null
            ? List<WatchedSingle>.from(
                json["episodes"].map((final e) => WatchedSingle.fromMap((e))),
              )
            : [],
        lastWatched = WatchedSingle.fromMap(json["lastWatched"]),
        watchedAt = DateTime.parse(json["watchedAt"]);

  void watching(final WatchedSingle episode) {
    final watchingNow = episodes.firstWhereOrNull(
      (final element) => element.filmDetails.url == episode.filmDetails.url,
    );
    if (watchingNow == null) {
      episodes.add(episode);
    } else {
      watchingNow.watching(episode.watchedInSec);
    }
    episodes.sort((final a, final b) =>
        a.filmDetails.seasonEpisodeTag
            ?.split("e")[1]
            .replaceAll("]", "")
            .compareTo(b.filmDetails.seasonEpisodeTag
                    ?.split("e")[1]
                    .replaceAll("]", "") ??
                "") ??
        0);
    lastWatched = episode;
    watchedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      "filmDetails": filmDetails.toMap(),
      "episodes": episodes.map((final episode) => episode.toMap()).toList(),
      "lastWatched": lastWatched.toMap(),
      "watchedAt": watchedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return "WatchedSerial(filmDetails: $filmDetails, episodes: $episodes, lastWatched: $lastWatched, watchedAt: $watchedAt)";
  }
}
