import 'package:filman_flutter/screens/film.dart';
import 'package:filman_flutter/types/season.dart';
import 'package:flutter/material.dart';

class EpisodesModal extends StatefulWidget {
  final List<Season> seasons;

  const EpisodesModal({super.key, required this.seasons});

  @override
  State<EpisodesModal> createState() => _EpisodesModalState();
}

class _EpisodesModalState extends State<EpisodesModal> {
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      for (Season season in widget.seasons)
        Column(
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
                title: Center(
                  child: Text(episode.episodeName),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => FilmScreen(
                            url: episode.episodeUrl,
                            title: episode.episodeName,
                            image: "",
                          )));
                },
              ),
          ],
        ),
      SizedBox(
        height: MediaQuery.of(context).viewInsets.bottom,
      )
    ]);
  }
}
