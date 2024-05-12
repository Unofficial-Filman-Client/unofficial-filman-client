import 'package:dio/dio.dart';
import 'package:filman_flutter/types/season.dart';
import 'package:html/parser.dart';

class Link {
  final String main;
  final String language;
  final String qualityVersion;
  final String link;
  final String hostingImgUrl;

  Link({
    required this.main,
    required this.qualityVersion,
    required this.language,
    required this.link,
    required this.hostingImgUrl,
  });
}

class DirectLink {
  final String link;
  final String qualityVersion;
  final String language;

  DirectLink({
    required this.link,
    required this.qualityVersion,
    required this.language,
  });
}

class FilmDetails {
  final String title;
  final String desc;
  final String releaseDate;
  final String viewCount;
  final String country;
  final List<String> categories;
  final bool isSerial;
  final List<Season>? seasons;
  final List<Link>? links;

  Future<List<DirectLink>> getDirect() async {
    List<DirectLink> directLinks = [];
    for (Link link in links ?? []) {
      if (link.main.toString().contains("vidoza")) {
        directLinks.add(DirectLink(
          link: await scrapVidoza(link.link),
          qualityVersion: link.qualityVersion,
          language: link.language,
        ));
      }
    }
    return directLinks;
  }

  Future<String> scrapVidoza(String url) async {
    final Dio dio = Dio();
    final response = await dio.get(url);
    final document = parse(response.data);

    final link = document.querySelector('source')?.attributes['src'];

    return Uri.parse(link ?? '').toString();
  }

  List<Season>? getSeasons() {
    seasons?.sort((a, b) => a.seasonTitle.compareTo(b.seasonTitle));
    return seasons;
  }

  FilmDetails({
    required this.title,
    required this.desc,
    required this.releaseDate,
    required this.viewCount,
    required this.country,
    required this.categories,
    required this.isSerial,
    this.seasons,
    this.links,
  });
}
