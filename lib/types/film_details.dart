import 'package:dio/dio.dart';
import 'package:unofficial_filman_client/types/links.dart';
import 'package:unofficial_filman_client/types/season.dart';
import 'package:html/parser.dart';

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
  final List<Link>? links;
  final bool isEpisode;
  final String? seasonEpisodeTag;
  final String? parentUrl;
  final String? prevEpisodeUrl;
  final String? nextEpisodeUrl;

  Future<List<Language>> getAvailableLanguages() async {
    List<Language> languages = [];
    for (Link link in links ?? []) {
      if (!languages.contains(link.language)) {
        languages.add(link.language);
      }
    }
    return languages;
  }

  Future<List<Quality>> getAvaliableQualitiesForLanguage(Language lang) async {
    List<Quality> qualities = [];
    for (Link link in links ?? []) {
      if (link.language == lang) {
        if (!qualities.contains(link.qualityVersion)) {
          qualities.add(link.qualityVersion);
        }
      }
    }
    qualities.sort();
    return qualities;
  }

  Future<List<DirectLink>> getDirects(Language lang, Quality quality) async {
    List<DirectLink> directLinks = [];
    for (Link link in links ?? []) {
      if (link.language != lang || link.qualityVersion != quality) {
        continue;
      }
      if (link.main.toString().contains("streamtape")) {
        directLinks.add(DirectLink(
            link: await scrapStreamtape(link.link),
            qualityVersion: link.qualityVersion,
            language: link.language,
            hostingImgUrl: link.hostingImgUrl));
      }
      if (link.main.toString().contains("vidoza")) {
        directLinks.add(DirectLink(
            link: await scrapVidoza(link.link),
            qualityVersion: link.qualityVersion,
            language: link.language,
            hostingImgUrl: link.hostingImgUrl));
      }
    }
    return directLinks;
  }

  Future<String> scrapVidoza(String url) async {
    final Dio dio = Dio();
    try {
      final response = await dio.get(url);
      final document = parse(response.data);

      if (document.body?.text == "File was deleted") {
        throw Exception('File was deleted');
      }

      final link = document.querySelector('source')?.attributes['src'];

      if (link == null) {
        throw Exception('No link found');
      }

      return Uri.parse(link).toString();
    } catch (e) {
      throw Exception('Error scraping Vidoza.net: ${e.toString()}');
    }
  }

  Future<String> scrapStreamtape(String url) async {
    final Dio dio = Dio();

    try {
      final response = await dio.get(url);

      final jsLineMatch = RegExp(
              r"(?<=document\.getElementById\('botlink'\)\.innerHTML = )(.*)(?=;)")
          .firstMatch(response.data);

      if (jsLineMatch == null || jsLineMatch.group(0) == null) {
        throw Exception('Error scraping Streamtape.com: No JS line found');
      }

      final String jsLine = jsLineMatch.group(0)!;

      final List<String> urls = RegExp(r"'([^']*)'")
          .allMatches(jsLine)
          .map((m) => m.group(0)!.replaceAll("'", ""))
          .toList();

      if (urls.length != 2) {
        throw Exception('Error scraping Streamtape.com: No URL in JS line');
      }

      final String base = urls[0];
      final String encoded = urls[1];

      final String fullUrl = 'https:$base${encoded.substring(4)}';

      final apiResponse = await dio.get(
        fullUrl,
        options: Options(
          followRedirects: false,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      final String? directLink = apiResponse.headers["location"]?.first;

      if (directLink == null) {
        throw Exception('Error scraping Streamtape.com: No direct link found');
      }

      return directLink;
    } catch (e) {
      throw Exception('Error scraping Streamtape.com: ${e.toString()}');
    }
  }

  List<Season> getSeasons() {
    seasons?.sort((a, b) => a.seasonTitle.compareTo(b.seasonTitle));
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

  FilmDetails.fromJSON(Map<String, dynamic> json)
      : url = json['url'],
        title = json['title'],
        desc = json['desc'],
        imageUrl = json['imageUrl'],
        releaseDate = json['releaseDate'],
        viewCount = json['viewCount'],
        country = json['country'],
        categories = List<String>.from(json['categories']),
        isSerial = json['isSerial'],
        isEpisode = json['isEpisode'],
        seasons = json['seasons'] != null
            ? List<Season>.from(json['seasons'].map((e) => Season.fromJSON(e)))
            : null,
        links = json['links'] != null
            ? List<Link>.from(json['links'].map((e) => Link.fromJSON(e)))
            : null,
        seasonEpisodeTag = json['seasonEpisodeTag'],
        parentUrl = json['parentUrl'],
        prevEpisodeUrl = json['prevEpisodeUrl'],
        nextEpisodeUrl = json['nextEpisodeUrl'];

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'desc': desc,
      'imageUrl': imageUrl,
      'releaseDate': releaseDate,
      'viewCount': viewCount,
      'country': country,
      'categories': categories,
      'isSerial': isSerial,
      'isEpisode': isEpisode,
      'seasons': seasons?.map((e) => e.toMap()).toList(),
      'links': links?.map((e) => e.toMap()).toList(),
      'seasonEpisodeTag': seasonEpisodeTag,
      'parentUrl': parentUrl,
      'prevEpisodeUrl': prevEpisodeUrl,
      'nextEpisodeUrl': nextEpisodeUrl,
    };
  }

  @override
  String toString() {
    return 'FilmDetails(title: $title, desc: $desc, releaseDate: $releaseDate, viewCount: $viewCount, country: $country, categories: $categories, isSerial: $isSerial, isEpisode: $isEpisode, seasons: $seasons, links: $links, seasonEpisodeTag: $seasonEpisodeTag, prevEpisodeUrl: $prevEpisodeUrl, nextEpisodeUrl: $nextEpisodeUrl)';
  }
}
