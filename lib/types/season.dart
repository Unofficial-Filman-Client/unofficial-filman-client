import 'package:flutter/material.dart';

class Episode {
  final String episodeName;
  final String episodeUrl;

  Episode({
    required this.episodeName,
    required this.episodeUrl,
  });
}

class Season {
  final String seasonTitle;
  final List<Episode> episodes;

  void addEpisode(Episode episode) {
    episodes.add(episode);
  }

  List<Episode> getEpisodes() {
    episodes.sort((a, b) => a.episodeName
        .split(" ")[0]
        .split("e")[1]
        .replaceAll("]", "")
        .compareTo(
            b.episodeName.split(" ")[0].split("e")[1].replaceAll("]", "")));

    return episodes;
  }

  Season({
    required this.seasonTitle,
    required this.episodes,
  });
}
