import "package:background_downloader/background_downloader.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:unofficial_filman_client/widgets/episodes.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  Widget _buildDownloadedCard(
      final BuildContext context, final DownloadedSingle download) {
    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (final context) =>
                    FilmanPlayer.fromDownload(downloaded: download),
              ));
            },
            onLongPress: () => _showDeleteDialog(context, download),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              child: FastCachedImage(url: download.film.imageUrl),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (final context) =>
                    FilmScreen.fromDetails(details: download.film),
              )),
              icon: const Icon(Icons.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedSerialCard(
      final BuildContext context, final DownloadedSerial download) {
    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                builder: (final context) =>
                    EpisodesModal(filmDetails: download.serial),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              child: FastCachedImage(
                  url: download.serial.imageUrl, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (final context) =>
                    FilmScreen.fromDetails(details: download.serial),
              )),
              icon: const Icon(Icons.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingCard(
      final BuildContext context, final Downloading download) {
    return Card(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12.0)),
                  child: FastCachedImage(
                    url: download.film.imageUrl,
                    fit: BoxFit.cover,
                    height: 256,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (download.isSerial)
                        Text(
                          download.film.seasonEpisodeTag ?? "",
                          style: const TextStyle(fontSize: 16.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      StreamBuilder<TaskStatusUpdate>(
                        stream: download.status.stream,
                        builder: (final context, final snapshot) {
                          if (!snapshot.hasData) {
                            return const Text("Brak danych");
                          }
                          final status = snapshot.data!.status;
                          if (status == TaskStatus.failed) {
                            return Text(
                              "Wystąpił błąd (${snapshot.data?.exception})",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          } else if (status == TaskStatus.running) {
                            return StreamBuilder<TaskProgressUpdate>(
                              stream: download.progress.stream,
                              builder:
                                  (final context, final progressSnapshot) =>
                                      Row(
                                children: [
                                  Text(
                                      "${((progressSnapshot.data?.progress ?? 0) * 100).toStringAsFixed(0)}%"),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                        value:
                                            progressSnapshot.data?.progress ??
                                                0.0),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Text("Brak danych");
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            top: 0,
            child: IconButton(
              onPressed: () {
                Provider.of<DownloadNotifier>(context, listen: false)
                    .cancelDownload(download);
              },
              icon: const Icon(Icons.cancel),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      final BuildContext context, final DownloadedSingle download) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Usuwanie z historii"),
        content: Consumer<SettingsNotifier>(
          builder: (final context, final settings, final child) => Text(
            "Czy na pewno chcesz usunąć \"${getDisplayTitle(download.film.title, settings)}\" z pobranych?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Usuń"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Consumer<DownloadNotifier>(
      builder: (final context, final value, final child) {
        final totalItems = value.downloaded.length +
            value.downloadedSerials.length +
            value.downloading.length;

        if (totalItems == 0) {
          return Center(
            child: Text(
              "Brak pobranych filmów",
              style: Theme.of(context).textTheme.labelLarge,
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 10,
            mainAxisExtent: 250,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: totalItems,
          itemBuilder: (final context, final index) {
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 250,
                child: Builder(
                  builder: (final context) {
                    if (index < value.downloaded.length) {
                      return _buildDownloadedCard(
                          context, value.downloaded[index]);
                    } else if (index <
                        value.downloaded.length +
                            value.downloadedSerials.length) {
                      return _buildDownloadedSerialCard(
                          context,
                          value.downloadedSerials[
                              index - value.downloaded.length]);
                    } else {
                      return _buildDownloadingCard(
                          context,
                          value.downloading[index -
                              value.downloaded.length -
                              value.downloadedSerials.length]);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
