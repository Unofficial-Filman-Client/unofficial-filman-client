import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/watched.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class WatchedPage extends StatefulWidget {
  const WatchedPage({super.key});

  @override
  State<WatchedPage> createState() => _WatchedPageState();
}

class _WatchedPageState extends State<WatchedPage> {
  Widget _buildWatchedFilmCard(final BuildContext context,
      final WatchedSingle film, final WatchedNotifier all) {
    return Card(
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (final context) => FilmanPlayer.fromDetails(
                    filmDetails: film.filmDetails,
                    startFrom: film.watchedInSec,
                    savedDuration: film.totalInSec,
                  ),
                ),
              );
            },
            onLongPress: () => showDialog(
              context: context,
              builder: (final context) {
                return AlertDialog(
                  title: const Text("Usuwanie z historii"),
                  content: Consumer<SettingsNotifier>(
                    builder: (final context, final settings, final child) =>
                        Text(
                      "Czy na pewno chcesz usunąć postęp oglądania \"${getDisplayTitle(film.filmDetails.title, settings)}\" z historii?",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Anuluj"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          Provider.of<WatchedNotifier>(context, listen: false)
                              .remove(film);
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text("Usuń"),
                    ),
                  ],
                );
              },
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: FastCachedImage(
                      url: film.filmDetails.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                LinearProgressIndicator(
                  value: film.watchedPercentage,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (film.filmDetails.isEpisode)
                          Column(
                            children: [
                              Text(
                                (film.filmDetails.seasonEpisodeTag?.split(" ")
                                          ?..removeAt(0))
                                        ?.join(" ") ??
                                    "",
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'S${film.parentSeason?.seasonTitle.replaceAll('Sezon ', '')}:O${1 + (film.parentSeason?.episodes.indexWhere((final e) => e.episodeUrl == film.filmDetails.url) ?? 0)} z ${film.parentSeason?.episodes.length}',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        else
                          Text(
                            "Pozostało: ${film.totalInSec ~/ 60} min",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: film.filmDetails.parentUrl != null
                ? IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (final context) => FilmScreen(
                            url: film.filmDetails.parentUrl!,
                            image: film.filmDetails.imageUrl,
                            title: film.filmDetails.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info),
                  )
                : IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (final context) =>
                            FilmScreen.fromDetails(details: film.filmDetails),
                      ),
                    ),
                    icon: const Icon(Icons.info),
                  ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Consumer<WatchedNotifier>(
      builder: (final context, final value, final child) {
        final List<WatchedSingle> combined = value.films +
            value.serials.map((final e) => e.lastWatched).toList();
        combined.sort((final a, final b) => b.watchedAt.compareTo(a.watchedAt));

        return combined.isEmpty
            ? Center(
                child: Text(
                  "Brak filmów w historii oglądania",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 250,
                ),
                padding: const EdgeInsets.all(10),
                itemCount: combined.length,
                itemBuilder: (final BuildContext context, final int index) {
                  final film = combined[index];
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 250,
                      child: _buildWatchedFilmCard(context, film, value),
                    ),
                  );
                },
              );
      },
    );
  }
}
