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

  Season({
    required this.seasonTitle,
    required this.episodes,
  });
}
