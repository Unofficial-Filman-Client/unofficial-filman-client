class Episode {
  final String episodeName;
  final String episodeUrl;

  Episode({
    required this.episodeName,
    required this.episodeUrl,
  });

  int getEpisodeNumber() {
    final RegExp regex = RegExp(r'\[s\d+e(\d+)\]');
    final Match? match = regex.firstMatch(episodeName);
    if (match != null && match.group(1) != null) {
      return int.parse(match.group(1)!);
    } else {
      return -1;
    }
  }

  String getEpisodeTitle() {
    final RegExp regex = RegExp(r'\[s\d+e\d+\] (.*)');
    final Match? match = regex.firstMatch(episodeName);
    if (match != null && match.group(1) != null) {
      return match.group(1)!;
    } else {
      return episodeName;
    }
  }
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
