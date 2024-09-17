import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/season.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/types/watched.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/utils/hosts.dart";
import "package:unofficial_filman_client/utils/select_dialog.dart";

class EpisodesModal extends StatefulWidget {
  final FilmDetails filmDetails;

  const EpisodesModal({super.key, required this.filmDetails});

  @override
  State<EpisodesModal> createState() => _EpisodesModalState();
}

class _EpisodesModalState extends State<EpisodesModal> {
  Map<String, FilmDetails> episodeDetails = {};
  List<Season> seasons = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      seasons = widget.filmDetails.getSeasons();
    });
    _loadEpisodeDescriptions();
  }

  @override
  void dispose() {
    super.dispose();
    episodeDetails.clear();
  }

  Future<void> _loadEpisodeDescriptions() async {
    final downloadedSerial = Provider.of<DownloadNotifier>(context,
            listen: false)
        .downloadedSerials
        .firstWhereOrNull((final s) => s.serial.url == widget.filmDetails.url);
    final savedSerial = Provider.of<WatchedNotifier>(context, listen: false)
        .serials
        .firstWhereOrNull((final element) =>
            element.filmDetails.url == widget.filmDetails.url);

    for (Season season in seasons) {
      if (!mounted) return;
      for (Episode episode in season.getEpisodes()) {
        if (!mounted) return;
        final watched = savedSerial?.episodes
                .firstWhereOrNull((final element) =>
                    element.filmDetails.url == episode.episodeUrl)
                ?.filmDetails ??
            downloadedSerial?.episodes
                .firstWhereOrNull((final e) => e.film.url == episode.episodeUrl)
                ?.film;
        if (watched != null) {
          if (!mounted) return;
          setState(() {
            episodeDetails[episode.episodeName] = watched;
          });
        } else {
          final FilmDetails data =
              await Provider.of<FilmanNotifier>(context, listen: false)
                  .getFilmDetails(episode.episodeUrl);
          if (!mounted) return;
          setState(() {
            episodeDetails[episode.episodeName] = data;
          });
        }
      }
    }
  }

  Widget _buildProgressBar(final WatchedSingle currentEpisode) {
    final Duration watched = Duration(seconds: currentEpisode.watchedInSec);
    final Duration total = Duration(seconds: currentEpisode.totalInSec);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${watched.inMinutes}:${(watched.inSeconds % 60).toString().padLeft(2, '0')}',
          ),
          const SizedBox(
            width: 5,
          ),
          Expanded(
              child: LinearProgressIndicator(
            value: currentEpisode.watchedPercentage,
          )),
          const SizedBox(
            width: 5,
          ),
          Text(
            '${total.inMinutes}:${(total.inSeconds % 60).toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadIcon(
      final BuildContext context, final FilmDetails filmDetails) {
    final downloaded = Provider.of<DownloadNotifier>(context, listen: false)
        .getEpisodeByUrl(widget.filmDetails, filmDetails.url);
    bool isDownloading = Provider.of<DownloadNotifier>(context, listen: false)
        .downloading
        .any((final element) => element.film.url == filmDetails.url);
    return IconButton(
      icon: isDownloading
          ? const CircularProgressIndicator()
          : Icon(downloaded != null ? Icons.save : Icons.download),
      onPressed: () async {
        if (!context.mounted ||
            downloaded != null ||
            filmDetails.links == null) {
          return;
        }
        final directs = await getDirects(filmDetails.links!);
        if (directs.isEmpty || !context.mounted) {
          return;
        }
        final (l, q) = await getUserSelectedPreferences(directs, context);
        if (l == null || q == null) {
          return;
        }
        Provider.of<DownloadNotifier>(context, listen: false).addFilmToDownload(
            filmDetails,
            l,
            q,
            Provider.of<SettingsNotifier>(context, listen: false),
            widget.filmDetails);
        setState(() {
          isDownloading = true;
        });
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final downloadedSerial = Provider.of<DownloadNotifier>(context)
        .downloadedSerials
        .firstWhereOrNull((final s) => s.serial.url == widget.filmDetails.url);

    return Consumer<WatchedNotifier>(
      builder: (final context, final watchedNotifier, final child) {
        final currentSerial = watchedNotifier.serials.firstWhereOrNull(
            (final s) => s.filmDetails.url == widget.filmDetails.url);

        return ListView.separated(
          itemCount: seasons.length,
          separatorBuilder: (final context, final index) =>
              const SizedBox(height: 16.0),
          itemBuilder: (final context, final index) {
            final Season season = seasons[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Center(
                    child: Text(
                      season.seasonTitle,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                for (Episode episode in season.getEpisodes())
                  Builder(
                    builder: (final context) {
                      final currentEpisode = currentSerial?.episodes
                          .firstWhereOrNull((final e) =>
                              e.filmDetails.url == episode.episodeUrl &&
                              e.watchedInSec > 0);
                      final downloadedEpisode = downloadedSerial?.episodes
                          .firstWhereOrNull(
                              (final e) => e.film.url == episode.episodeUrl);

                      return ListTile(
                        title: Row(
                          children: [
                            Text(
                              episode.getEpisodeNumber().toString(),
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 50),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(episode.getEpisodeTitle()),
                                  const SizedBox(height: 4.0),
                                  episodeDetails.isNotEmpty
                                      ? episodeDetails[episode.episodeName]
                                                  ?.desc
                                                  .isNotEmpty ==
                                              true
                                          ? episodeDetails[episode.episodeName]!
                                                      .desc ==
                                                  widget.filmDetails.desc
                                              ? const Text(
                                                  "Brak opisu odcinka",
                                                  style: TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              : Text(
                                                  episodeDetails[
                                                          episode.episodeName]!
                                                      .desc,
                                                  style: const TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                          : const LinearProgressIndicator()
                                      : const LinearProgressIndicator(),
                                  currentEpisode != null
                                      ? _buildProgressBar(currentEpisode)
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: episodeDetails[episode.episodeName] != null
                                  ? _buildDownloadIcon(context,
                                      episodeDetails[episode.episodeName]!)
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context)
                              .push(MaterialPageRoute(builder: (final context) {
                            if (downloadedEpisode != null) {
                              return FilmanPlayer.fromDownload(
                                downloaded: downloadedEpisode,
                                parentDownloaded: downloadedSerial,
                              );
                            }
                            if (episodeDetails[episode.episodeName] != null) {
                              if (currentEpisode != null) {
                                return FilmanPlayer.fromDetails(
                                  filmDetails:
                                      episodeDetails[episode.episodeName],
                                  parentDetails: widget.filmDetails,
                                  startFrom: currentEpisode.watchedInSec,
                                  savedDuration: currentEpisode.totalInSec,
                                );
                              }
                              return FilmanPlayer.fromDetails(
                                filmDetails:
                                    episodeDetails[episode.episodeName],
                                parentDetails: widget.filmDetails,
                              );
                            }

                            if (currentEpisode != null) {
                              return FilmanPlayer(
                                targetUrl: episode.episodeUrl,
                                parentDetails: widget.filmDetails,
                                startFrom: currentEpisode.watchedInSec,
                                savedDuration: currentEpisode.totalInSec,
                              );
                            }

                            return FilmanPlayer(
                                targetUrl: episode.episodeUrl,
                                parentDetails: widget.filmDetails);
                          }));
                        },
                      );
                    },
                  )
              ],
            );
          },
        );
      },
    );
  }
}
