class Episode {
  final String episodeName;
  final String episodeUrl;

  Episode({
    required this.episodeName,
    required this.episodeUrl,
  });

  Episode.fromMap(final Map<String, dynamic> json)
      : episodeName = json["episodeName"],
        episodeUrl = json["episodeUrl"];

  int getEpisodeNumber() {
    final RegExp regex = RegExp(r"\[s\d+e(\d+)\]");
    final Match? match = regex.firstMatch(episodeName);
    if (match != null && match.group(1) != null) {
      return int.parse(match.group(1)!);
    } else {
      return -1;
    }
  }

  String getEpisodeTitle() {
    final RegExp regex = RegExp(r"\[s\d+e\d+\] (.*)");
    final Match? match = regex.firstMatch(episodeName);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    } else {
      return episodeName;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "episodeName": episodeName,
      "episodeUrl": episodeUrl,
    };
  }

  @override
  String toString() {
    return "Episode{episodeName: $episodeName, episodeUrl: $episodeUrl}";
  }
}

class Season {
  final String seasonTitle;
  final List<Episode> episodes;

  void addEpisode(final Episode episode) {
    episodes.add(episode);
  }

  List<Episode> getEpisodes() {
    episodes.sort((final a, final b) =>
        a.getEpisodeNumber().compareTo(b.getEpisodeNumber()));

    return episodes;
  }

  Season({
    required this.seasonTitle,
    required this.episodes,
  });

  Season.fromMap(final Map<String, dynamic> json)
      : seasonTitle = json["seasonTitle"],
        episodes = List<Episode>.from(
            json["episodes"].map((final e) => Episode.fromMap(e)));

  Map<String, dynamic> toMap() {
    return {
      "seasonTitle": seasonTitle,
      "episodes": episodes.map((final e) => e.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return "Season{seasonTitle: $seasonTitle, episodes: $episodes}";
  }
}
