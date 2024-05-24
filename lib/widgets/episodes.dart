import 'package:filman_flutter/notifiers/filman.dart';
import 'package:filman_flutter/screens/player.dart';
import 'package:filman_flutter/types/film_details.dart';
import 'package:filman_flutter/types/season.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    loadEpisodeDescriptions();
  }

  @override
  void dispose() {
    super.dispose();
    episodeDescriptions.clear();
  }

  Future<void> loadEpisodeDescriptions() async {
    for (Season season in seasons) {
      for (Episode episode in season.getEpisodes()) {
        FilmDetails data =
            await Provider.of<FilmanNotifier>(context, listen: false)
                .getFilmDetails(episode.episodeUrl);
        if (mounted) {
          setState(() {
            episodeDescriptions[episode.episodeName] = data;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: seasons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) {
        Season season = seasons[index];
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
              ListTile(
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
                                          .isNotEmpty ??
                                      false
                                  ? Text(
                                      episodeDescriptions[episode.episodeName]
                                              ?.desc ??
                                          "Błąd pobierania opisu",
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const LinearProgressIndicator()
                              : const LinearProgressIndicator(),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeRight,
                    DeviceOrientation.landscapeLeft
                  ]);
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    if (episodeDescriptions[episode.episodeName] != null) {
                      return FilmanPlayer.fromDetails(
                        filmDetails: episodeDescriptions[episode.episodeName],
                        parentDetails: widget.filmDetails,
                      );
                    } else {
                      return FilmanPlayer(
                          targetUrl: episode.episodeUrl,
                          parentDetails: widget.filmDetails);
                    }
                  }));
                },
              ),
          ],
        );
      },
    );
  }
}
