import "dart:async";
import "dart:convert";
import "dart:io";

import "package:background_downloader/background_downloader.dart";
import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:shared_preferences/shared_preferences.dart";

class DownloadNotifier extends ChangeNotifier {
  final List<Downloading> _downloading = [];
  final List<DownloadedSingle> _downloaded = [];
  final List<DownloadedSerial> _downloadedSerials = [];

  List<Downloading> get downloading => _downloading;
  List<DownloadedSingle> get downloaded => _downloaded;
  List<DownloadedSerial> get downloadedSerials => _downloadedSerials;

  SharedPreferences? prefs;

  void loadSaved() async {
    prefs = await SharedPreferences.getInstance();
    final downloaded = prefs?.getStringList("downloaded");
    final downloadedSerials = prefs?.getStringList("downloadedSerials");
    if (downloaded != null) {
      _downloaded.addAll(
        downloaded
            .map((final e) => DownloadedSingle.fromMap(jsonDecode(e)))
            .toList(),
      );
    }
    if (downloadedSerials != null) {
      _downloadedSerials.addAll(
        downloadedSerials
            .map((final e) => DownloadedSerial.fromMap(jsonDecode(e)))
            .toList(),
      );
    }
  }

  String _decompress(final String compressed) {
    final decodeBase64Json = base64.decode(compressed);
    final decodegZipJson = GZipCodec().decode(decodeBase64Json);
    final originalJson = utf8.decode(decodegZipJson);
    return originalJson;
  }

  Future loadDownloads() async {
    loadSaved();
    await FileDownloader().trackTasks();

    FileDownloader().configureNotification(
        running:
            const TaskNotification("Pobieranie", "{displayName} {progress}"),
        progressBar: true);

    FileDownloader().updates.listen((final update) async {
      try {
        Downloading? downloading = _downloading.firstWhereOrNull(
            (final element) => element.taskId == update.task.taskId);
        if (downloading == null) {
          downloading = Downloading.fromMap(
              jsonDecode(_decompress(update.task.metaData)),
              update.task as DownloadTask);
          _downloading.add(downloading);
          notifyListeners();
        }
        switch (update) {
          case TaskStatusUpdate():
            debugPrint("task: ${downloading.displayName} ${update.status}");
            switch (update.status) {
              case TaskStatus.complete:
                _downloading.remove(downloading);
                if (downloading.isSerial) {
                  final existingSerial = _downloadedSerials.firstWhereOrNull(
                      (final serial) =>
                          serial.serial.url == downloading?.parentDetails?.url);
                  if (existingSerial != null) {
                    existingSerial.episodes
                        .add(DownloadedSingle.fromDownloading(downloading));
                  } else {
                    _downloadedSerials.add(DownloadedSerial(
                        serial: downloading.parentDetails!,
                        episodes: [
                          DownloadedSingle.fromDownloading(downloading)
                        ]));
                  }
                  prefs?.setStringList(
                      "downloadedSerials",
                      _downloadedSerials
                          .map((final e) => jsonEncode(e.toMap()))
                          .toList());
                  debugPrint(
                      "saved ${prefs?.getStringList("downloadedSerials")}");
                } else {
                  _downloaded
                      .add(DownloadedSingle.fromDownloading(downloading));
                  prefs?.setStringList(
                      "downloaded",
                      _downloaded
                          .map((final e) => jsonEncode(e.toMap()))
                          .toList());
                }

                break;
              case TaskStatus.canceled:
                _downloading.remove(downloading);
                notifyListeners();
                break;
              default:
                downloading.status.add(update);
                notifyListeners();
            }
            break;

          case TaskProgressUpdate():
            downloading.progress.add(update);
            notifyListeners();
            break;
        }
      } catch (err) {
        debugPrint("Download error: $err");
      }
    });
  }

  Future addFilmToDownload(final FilmDetails film, final Language language,
      final Quality quality, final SettingsNotifier settings,
      [final FilmDetails? parentDetails]) async {
    final Downloading download = Downloading(
        film: film,
        parentDetails: parentDetails,
        displayName: getDisplayTitle(film.title, settings),
        language: language,
        quality: quality);
    _downloading.add(download);

    final queued = await FileDownloader().enqueue(await download.getTask());

    if (!queued) {
      throw Exception("Failed to enqueue download");
    }

    notifyListeners();
  }

  void cancelDownload(final Downloading download) {
    FileDownloader().cancelTaskWithId(download.taskId);
    _downloading.remove(download);

    notifyListeners();
  }

  DownloadedSingle? getEpisodeByUrl(
      final FilmDetails serial, final String url) {
    return _downloadedSerials
        .firstWhereOrNull((final s) => s.serial.url == serial.url)
        ?.episodes
        .firstWhereOrNull((final episode) => episode.film.url == url);
  }
}
