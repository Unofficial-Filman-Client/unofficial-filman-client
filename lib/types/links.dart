enum Language implements Comparable<Language> {
  dubbing(language: 'Dubbing'),
  dubbingKino(language: 'Dubbing_Kino'),
  eng(language: 'ENG'),
  lektor(language: 'Lektor'),
  lektorIVO(language: 'Lektor_IVO'),
  napisy(language: 'Napisy'),
  napisyTansl(language: 'Napisy_Tansl'),
  pl(language: 'PL');

  const Language({
    required this.language,
  });

  final String language;

  @override
  int compareTo(Language other) => language.compareTo(other.language);

  @override
  String toString() => language;
}

enum Quality implements Comparable<Quality> {
  p360(quality: '360p'),
  p480(quality: '480p'),
  p720(quality: '720p'),
  p1080(quality: '1080p');

  const Quality({required this.quality});

  final String quality;

  @override
  int compareTo(Quality other) => int.parse(quality.replaceAll('p', ''))
      .compareTo(int.parse(other.quality.replaceAll('p', '')));

  @override
  String toString() => quality;
}

class Link {
  final String main;
  final Language language;
  final Quality qualityVersion;
  final String link;
  final String hostingImgUrl;

  Link({
    required this.main,
    required String qualityVersion,
    required String language,
    required this.link,
    required this.hostingImgUrl,
  })  : qualityVersion =
            Quality.values.firstWhere((e) => e.quality == qualityVersion),
        language = Language.values.firstWhere((e) => e.language == language);

  Link.fromJSON(Map<String, dynamic> json)
      : main = json['main'],
        qualityVersion = Quality.values
            .firstWhere((e) => e.quality == json['qualityVersion']),
        language =
            Language.values.firstWhere((e) => e.language == json['language']),
        link = json['link'],
        hostingImgUrl = json['hostingImgUrl'];

  Map<String, dynamic> toMap() {
    return {
      'main': main,
      'qualityVersion': qualityVersion.quality,
      'language': language.language,
      'link': link,
      'hostingImgUrl': hostingImgUrl,
    };
  }
}

class DirectLink {
  final String link;
  final Quality qualityVersion;
  final Language language;
  final String hostingImgUrl;

  DirectLink(
      {required this.link,
      required this.qualityVersion,
      required this.language,
      required this.hostingImgUrl});

  @override
  String toString() =>
      'DirectLink(link: $link, qualityVersion: $qualityVersion, language: $language, hostingImgUrl: $hostingImgUrl)';
}