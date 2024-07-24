import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/season.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/types/watched.dart";

class EpisodesModal extends StatefulWidget {
  final FilmDetails filmDetails;

  const EpisodesModal({super.key, required this.filmDetails});

  @override
  State<EpisodesModal> createState() => _EpisodesModalState();
}

class _EpisodesModalState extends State<EpisodesModal> {
  Map<String, FilmDetails> episodeDescriptions = {};
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
    episodeDescriptions.clear();
  }

  Future<void> _loadEpisodeDescriptions() async {
    final savedSerial = Provider.of<WatchedNotifier>(context, listen: false)
        .serials
        .firstWhereOrNull(
            (final element) => element.filmDetails.url == widget.filmDetails.url);

    for (Season season in seasons) {
      for (Episode episode in season.getEpisodes()) {
        final watched = savedSerial?.episodes.firstWhereOrNull(
            (final element) => element.filmDetails.url == episode.episodeUrl);
        if (watched != null) {
          setState(() {
            episodeDescriptions[episode.episodeName] = watched.filmDetails;
          });
        } else {
          final FilmDetails data =
              await Provider.of<FilmanNotifier>(context, listen: false)
                  .getFilmDetails(episode.episodeUrl);
          setState(() {
            episodeDescriptions[episode.episodeName] = data;
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

  @override
  Widget build(final BuildContext context) {
    return Consumer<WatchedNotifier>(
      builder: (final context, final watchedNotifier, final child) => ListView.separated(
        itemCount: seasons.length,
        separatorBuilder: (final context, final index) => const SizedBox(height: 16.0),
        itemBuilder: (final context, final index) {
          final Season season = seasons[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                    final currentSerial = watchedNotifier.serials
                        .firstWhereOrNull(
                            (final s) => s.filmDetails.url == widget.filmDetails.url);

                    final currentEpisode = currentSerial?.episodes
                        .firstWhereOrNull((final e) =>
                            e.filmDetails.url == episode.episodeUrl &&
                            e.watchedInSec > 0);
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
                                episodeDescriptions.isNotEmpty
                                    ? episodeDescriptions[episode.episodeName]
                                                ?.desc
                                                .isNotEmpty ==
                                            true
                                        ? episodeDescriptions[
                                                        episode.episodeName]!
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
                                                episodeDescriptions[
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
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (final context) {
                          if (episodeDescriptions[episode.episodeName] !=
                              null) {
                            if (currentEpisode != null) {
                              return FilmanPlayer.fromDetails(
                                filmDetails:
                                    episodeDescriptions[episode.episodeName],
                                parentDetails: widget.filmDetails,
                                startFrom: currentEpisode.watchedInSec,
                                savedDuration: currentEpisode.totalInSec,
                              );
                            }
                            return FilmanPlayer.fromDetails(
                              filmDetails:
                                  episodeDescriptions[episode.episodeName],
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
      ),
    );
  }
}
