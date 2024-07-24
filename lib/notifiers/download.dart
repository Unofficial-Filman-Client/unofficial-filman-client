import "dart:async";
import "dart:convert";

import "package:background_downloader/background_downloader.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/utils/titlte.dart";

class DownloadNotifier extends ChangeNotifier {
  final List<Download> _downloads = [];

  List<Download> get downloads => _downloads;

  Future loadDownloads() async {
    await FileDownloader().trackTasks();

    FileDownloader().configureNotification(
        running:
            const TaskNotification("Pobieranie", "{displayName} {progress}"),
        progressBar: true);

    FileDownloader().updates.listen((final update) async {
      try {
        Download? download = _downloads.firstWhereOrNull(
            (final element) => element.taskId == update.task.taskId);
        if (download == null) {
          download = Download.fromMap(
              jsonDecode(update.task.metaData), update.task as DownloadTask);
          _downloads.add(download);
          notifyListeners();
        }
        switch (update) {
          case TaskStatusUpdate():
            debugPrint("task: ${download.displayName} ${update.status}");
            download.status.add(update);
            break;

          case TaskProgressUpdate():
            download.progress.add(update);
        }
      } catch (err) {
        debugPrint("Download error: $err");
      }
    });

    notifyListeners();
  }

  void addFilmToDownload(final FilmDetails film, final Language language, final Quality quality,
      final SettingsNotifier settings) async {
    final Download download = Download(
        film: film,
        displayName: getDisplayTitle(film.title, settings),
        language: language,
        quality: quality);
    _downloads.add(download);

    final queued = await FileDownloader().enqueue(await download.getTask());

    if (!queued) {
      throw Exception("Failed to enqueue download");
    }

    notifyListeners();
  }
}
