import "dart:async";
import "dart:convert";
import "dart:io";

import "package:background_downloader/background_downloader.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/utils/hosts.dart";

class Downloading {
  final FilmDetails? parentDetails;
  final FilmDetails film;
  final String filename;
  final Quality quality;
  final Language language;
  final String displayName;
  StreamController<TaskProgressUpdate> progress = StreamController.broadcast();
  final StreamController<TaskStatusUpdate> status =
      StreamController.broadcast();

  Downloading(
      {required this.film,
      required this.displayName,
      required this.quality,
      required this.language,
      this.parentDetails})
      : filename = "${Uri.encodeComponent(film.title)}.mp4";

  get isSerial => film.isEpisode && parentDetails != null;

  DownloadTask? _task;

  Map<String, dynamic> toMap() {
    return {
      "film": film.toMap(),
      "parentDetails": parentDetails?.toMap(),
      "quality": quality.toString(),
      "language": language.toString(),
      "displayName": displayName
    };
  }

  Downloading.fromMap(final Map<String, dynamic> map, final DownloadTask task)
      : film = FilmDetails.fromMap(map["film"]),
        parentDetails = map["parentDetails"] != null
            ? FilmDetails.fromMap(map["parentDetails"])
            : null,
        quality = Quality.values.firstWhere(
            (final element) => element.toString() == map["quality"]),
        language = Language.values.firstWhere(
            (final element) => element.toString() == map["language"]),
        displayName = map["displayName"],
        filename =
            "${Uri.encodeComponent(FilmDetails.fromMap(map["film"]).title)}.mp4",
        _task = task;

  String get taskId {
    if (_task == null) {
      throw Exception("Task not initialized");
    }
    return _task!.taskId;
  }

  Future<DownloadTask> getTask() async {
    if (_task == null) {
      final directs = await getDirects(film.links ?? []);
      directs.removeWhere((final link) =>
          link.language != language ||
          link.qualityVersion != quality ||
          (link.link.contains(".m3u8")));

      final DirectLink? direct = (directs..shuffle()).firstOrNull;
      if (direct == null) {
        throw Exception("No host to download from found");
      }
      _task = DownloadTask(
          url: direct.link,
          filename: filename,
          displayName: displayName,
          metaData: _compress(jsonEncode(toMap())),
          updates: Updates.statusAndProgress);
    }

    return _task!;
  }

  String _compress(final String json) {
    final enCodedJson = utf8.encode(json);
    final gZipJson = GZipCodec().encode(enCodedJson);
    final base64Json = base64.encode(gZipJson);
    return base64Json;
  }
}

class DownloadedSingle {
  final FilmDetails film;
  final String filename;
  final Quality quality;
  final Language language;
  final String displayName;

  // Downloaded(
  //     {required this.film,
  //     required this.displayName,
  //     required this.quality,
  //     required this.language})
  //     : filename = "${film.title.replaceAll(' ', '_').replaceAll('/', '')}.mp4";

  DownloadedSingle.fromDownloading(final Downloading downloading)
      : film = downloading.film,
        displayName = downloading.displayName,
        quality = downloading.quality,
        language = downloading.language,
        filename = downloading.filename;

  DownloadedSingle.fromMap(final Map<String, dynamic> map)
      : film = FilmDetails.fromMap(map["film"]),
        quality = Quality.values.firstWhere(
            (final element) => element.toString() == map["quality"]),
        language = Language.values.firstWhere(
            (final element) => element.toString() == map["language"]),
        displayName = map["displayName"],
        filename =
            "${Uri.encodeComponent(FilmDetails.fromMap(map["film"]).title)}.mp4";

  Map<String, dynamic> toMap() {
    return {
      "film": film.toMap(),
      "quality": quality.toString(),
      "language": language.toString(),
      "displayName": displayName
    };
  }
}

class DownloadedSerial {
  final FilmDetails serial;
  final List<DownloadedSingle> episodes;

  DownloadedSerial({required this.serial, required this.episodes});

  DownloadedSerial.fromMap(final Map<String, dynamic> map)
      : serial = FilmDetails.fromMap(map["serial"]),
        episodes = (map["episodes"] as List)
            .map((final episode) => DownloadedSingle.fromMap(episode))
            .toList();

  Map<String, dynamic> toMap() {
    return {
      "serial": serial.toMap(),
      "episodes": episodes.map((final episode) => episode.toMap()).toList()
    };
  }
}
