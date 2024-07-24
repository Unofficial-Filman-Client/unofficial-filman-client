enum Language implements Comparable<Language> {
  dubbing(language: "Dubbing"),
  dubbingKino(language: "Dubbing_Kino"),
  eng(language: "ENG"),
  lektor(language: "Lektor"),
  lektorIVO(language: "Lektor_IVO"),
  napisy(language: "Napisy"),
  napisyTansl(language: "Napisy_Tansl"),
  pl(language: "PL");

  const Language({
    required this.language,
  });

  final String language;

  @override
  int compareTo(final Language other) => language.compareTo(other.language);

  @override
  String toString() => language;
}

enum Quality implements Comparable<Quality> {
  p360(quality: "360p"),
  p480(quality: "480p"),
  p720(quality: "720p"),
  p1080(quality: "1080p");

  const Quality({required this.quality});

  final String quality;

  @override
  int compareTo(final Quality other) => int.parse(quality.replaceAll("p", ""))
      .compareTo(int.parse(other.quality.replaceAll("p", "")));

  @override
  String toString() => quality;
}

class Host {
  final String main;
  final Language language;
  final Quality qualityVersion;
  final String link;

  Host({
    required this.main,
    required final String qualityVersion,
    required final String language,
    required this.link,
  })  : qualityVersion =
            Quality.values.firstWhere((final e) => e.quality == qualityVersion),
        language = Language.values.firstWhere((final e) => e.language == language);

  Host.fromMap(final Map<String, dynamic> json)
      : main = json["main"],
        qualityVersion = Quality.values
            .firstWhere((final e) => e.quality == json["qualityVersion"]),
        language =
            Language.values.firstWhere((final e) => e.language == json["language"]),
        link = json["link"];

  Map<String, dynamic> toMap() {
    return {
      "main": main,
      "qualityVersion": qualityVersion.quality,
      "language": language.language,
      "link": link,
    };
  }
}

class DirectLink {
  final String link;
  final Quality qualityVersion;
  final Language language;

  DirectLink({
    required this.link,
    required this.qualityVersion,
    required this.language,
  });

  @override
  String toString() =>
      "DirectLink(link: $link, qualityVersion: $qualityVersion, language: $language)";
}
