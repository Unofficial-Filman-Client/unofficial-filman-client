import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/types/season.dart";

class FilmDetails {
  final String url;
  final String title;
  final String desc;
  final String imageUrl;
  final String releaseDate;
  final String viewCount;
  final String country;
  final List<String> categories;
  final bool isSerial;
  final List<Season>? seasons;
  final List<Host>? links;
  final bool isEpisode;
  final String? seasonEpisodeTag;
  final String? parentUrl;
  final String? prevEpisodeUrl;
  final String? nextEpisodeUrl;

  List<Season> getSeasons() {
    seasons?.sort((final a, final b) {
      final aInt = int.tryParse(a.seasonTitle.replaceFirst("Sezon ", ""));
      final bInt = int.tryParse(b.seasonTitle.replaceFirst("Sezon ", ""));
      if (aInt != null && bInt != null) {
        return aInt.compareTo(bInt);
      }
      return a.seasonTitle.compareTo(b.seasonTitle);
    });
    return seasons ?? [];
  }

  FilmDetails({
    required this.url,
    required this.title,
    required this.desc,
    required this.imageUrl,
    required this.releaseDate,
    required this.viewCount,
    required this.country,
    required this.categories,
    required this.isSerial,
    required this.isEpisode,
    this.seasons,
    this.links,
    this.seasonEpisodeTag,
    this.parentUrl,
    this.prevEpisodeUrl,
    this.nextEpisodeUrl,
  });

  FilmDetails.fromMap(final Map<String, dynamic> json)
      : url = json["url"],
        title = json["title"],
        desc = json["desc"],
        imageUrl = json["imageUrl"],
        releaseDate = json["releaseDate"],
        viewCount = json["viewCount"],
        country = json["country"],
        categories = List<String>.from(json["categories"]),
        isSerial = json["isSerial"],
        isEpisode = json["isEpisode"],
        seasons = json["seasons"] != null
            ? List<Season>.from(
                json["seasons"].map((final e) => Season.fromMap(e)))
            : null,
        links = json["links"] != null
            ? List<Host>.from(json["links"]
                .map((final e) {
                  try {
                    return Host.fromMap(e);
                  } catch (err) {
                    return null;
                  }
                })
                .where((final element) => element != null)
                .toList())
            : null,
        seasonEpisodeTag = json["seasonEpisodeTag"],
        parentUrl = json["parentUrl"],
        prevEpisodeUrl = json["prevEpisodeUrl"],
        nextEpisodeUrl = json["nextEpisodeUrl"];

  Map<String, dynamic> toMap() {
    return {
      "url": url,
      "title": title,
      "desc": desc,
      "imageUrl": imageUrl,
      "releaseDate": releaseDate,
      "viewCount": viewCount,
      "country": country,
      "categories": categories,
      "isSerial": isSerial,
      "isEpisode": isEpisode,
      "seasons": seasons?.map((final e) => e.toMap()).toList(),
      "links": links?.map((final e) => e.toMap()).toList(),
      "seasonEpisodeTag": seasonEpisodeTag,
      "parentUrl": parentUrl,
      "prevEpisodeUrl": prevEpisodeUrl,
      "nextEpisodeUrl": nextEpisodeUrl,
    };
  }

  @override
  String toString() {
    return "FilmDetails(title: $title, desc: $desc, releaseDate: $releaseDate, viewCount: $viewCount, country: $country, categories: $categories, isSerial: $isSerial, isEpisode: $isEpisode, seasons: $seasons, links: $links, seasonEpisodeTag: $seasonEpisodeTag, prevEpisodeUrl: $prevEpisodeUrl, nextEpisodeUrl: $nextEpisodeUrl)";
  }
}
