import "dart:async";
import "dart:convert";

import "package:background_downloader/background_downloader.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/utils/hosts.dart";

class Download {
  final FilmDetails film;
  final String filename;
  final Quality quality;
  final Language language;
  final String displayName;
  StreamController<TaskProgressUpdate> progress = StreamController();
  final StreamController<TaskStatusUpdate> status = StreamController();

  Download(
      {required this.film,
      required this.displayName,
      required this.quality,
      required this.language})
      : filename = "${film.title.replaceAll(' ', '_').replaceAll('/', '')}.mp4";

  DownloadTask? _task;

  Map<String, dynamic> toMap() {
    return {
      "film": film.toMap(),
      "quality": quality.toString(),
      "language": language.toString(),
      "displayName": displayName
    };
  }

  Download.fromMap(final Map<String, dynamic> map, final DownloadTask task)
      : film = FilmDetails.fromMap(map["film"]),
        quality = Quality.values
            .firstWhere((final element) => element.toString() == map["quality"]),
        language = Language.values
            .firstWhere((final element) => element.toString() == map["language"]),
        displayName = map["displayName"],
        filename =
            "${FilmDetails.fromMap(map['film']).title.replaceAll(' ', '_').replaceAll('/', '')}.mp4",
        _task = task;

  String get taskId {
    if (_task == null) {
      throw Exception("Task not initialized");
    }
    return _task!.taskId;
  }

  Future<DownloadTask> getTask() async {
    if (_task == null) {
      final DirectLink? direct =
          (await getDirects(film.links ?? [], language, quality)
                ..shuffle())
              .firstOrNull;
      if (direct == null) {
        throw Exception("No host to download from found");
      }
      _task = DownloadTask(
          url: direct.link,
          filename: filename,
          displayName: displayName,
          metaData: jsonEncode(toMap()),
          updates: Updates.statusAndProgress);
    }

    return _task!;
  }
}
