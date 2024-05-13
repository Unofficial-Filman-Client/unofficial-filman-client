import 'dart:collection';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:filman_flutter/types/film.dart';
import 'package:filman_flutter/types/film_details.dart';
import 'package:filman_flutter/types/home_page.dart';
import 'package:filman_flutter/types/login_response.dart';
import 'package:filman_flutter/types/search_results.dart';
import 'package:filman_flutter/types/season.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';

class FilmanModel extends ChangeNotifier {
  final List<String> cookies = [];

  UnmodifiableListView<String> get items => UnmodifiableListView(cookies);
  SharedPreferences? prefs;
  late final Dio dio;

  Future<void> initPrefs() async {
    dio = Dio();
    prefs = await SharedPreferences.getInstance();
    cookies.addAll(prefs?.getStringList('cookies') ?? []);
  }

  void logout() {
    cookies.clear();
    prefs?.remove('cookies');
  }

  Future<LoginResponse> loginToFilman(login, password) async {
    try {
      final response = await dio.post(
        "https://filman.cc/logowanie",
        data: {'login': login, 'password': password, 'submit': ""},
        options: Options(
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            followRedirects: false,
            validateStatus: (status) {
              return true;
            }),
      );

      final cookiesHeader = response.headers["set-cookie"];

      if (cookiesHeader != null) {
        cookies.clear();
        cookies.addAll(cookiesHeader);
        prefs?.setStringList('cookies', cookies);
      }

      LoginResponse loginResponse =
          LoginResponse(success: response.statusCode == 302);

      final document = parse(response.data);

      document.querySelectorAll('.alert').forEach((element) {
        final error = element.text.trim();
        if (error.isNotEmpty) {
          loginResponse.addError(error);
        }
      });

      return loginResponse;
    } catch (identifier) {
      LoginResponse loginResponse = LoginResponse(success: false);
      loginResponse.addError('Error occurred while logging in: $identifier');
      return loginResponse;
    }
  }

  Future<HomePage> getFilmanPage() async {
    final response = await dio.get(
      "https://filman.cc/",
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return true;
        },
        headers: {'cookie': cookies.join('; ')},
      ),
    );

    if (response.headers['location'] != null) {
      logout();
      throw Exception(
          'GET https://filman.cc/ redirect to ${response.headers['location']}');
    }

    final document = parse(response.data);

    final homePage = HomePage();

    for (final list in document.querySelectorAll('div[id=item-list]')) {
      for (final filmDOM in list.children) {
        final poster = filmDOM.querySelector('.poster');
        final String title =
            poster?.querySelector('a')?.attributes['title']?.trim() ??
                "Brak danych";
        final String desc =
            poster?.querySelector('a')?.attributes['data-text']?.trim() ??
                "Brak danych";
        final String imageUrl =
            poster?.querySelector('img')?.attributes['src'] ?? "Brak danych";
        // final String qualityVersion =
        //     poster?.querySelector('.quality-version')?.text.trim() ??
        //         "Brak danych o jakości";
        // final String viewCount = poster?.querySelector('.view')?.text.trim() ??
        //     "Brak danych o ilości odsłon";
        final String link =
            poster?.querySelector('a')?.attributes['href'] ?? "Brak danych";

        final category =
            list.parent?.querySelector("h3")?.text.trim() ?? "INNE";
        homePage.addFilm(category,
            Film(title: title, desc: desc, imageUrl: imageUrl, link: link));
      }
    }

    return homePage;
  }

  Future<SearchResults> searchInFilman(String query) async {
    final response = await dio.get(
      "https://filman.cc/item",
      queryParameters: {"phrase": query},
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return true;
        },
        headers: {'cookie': cookies.join('; ')},
      ),
    );
    final document = parse(response.data);

    final searchResults = SearchResults();
    final films = document.querySelectorAll('.col-xs-6.col-sm-3.col-lg-2');

    for (final filmDOM in films) {
      final poster = filmDOM.querySelector('.poster');
      final title =
          filmDOM.querySelector('.film_title')?.text.trim() ?? 'Brak danych';
      final desc =
          poster?.querySelector('a')?.attributes['data-text']?.trim() ??
              'Brak danych';
      // final releaseDate = filmDOM.querySelector('.film_year')?.text.trim();
      final imageUrl =
          poster?.querySelector('img')?.attributes['src']?.trim() ??
              'Brak danych';
      // final qualityVersion =
      //     poster?.querySelector('a .quality-version')?.text.trim() ??
      //         'Brak danych o jakości';
      // final rating = poster?.querySelector('a .rate')?.text.trim();
      final link =
          poster?.querySelector('a')?.attributes['href'] ?? 'Brak danych';

      searchResults.addFilm(
          Film(title: title, desc: desc, imageUrl: imageUrl, link: link));
    }

    return searchResults;
  }

  Future<FilmDetails> getFilmDetails(String link) async {
    final response = await dio.get(
      link,
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return true;
        },
        headers: {'cookie': cookies.join('; ')},
      ),
    );

    if (response.headers['location'] != null) {
      throw Exception('GET $link redirect to ${response.headers['location']}');
    }

    if (response.statusCode != 200) {
      throw Exception('GET $link return ${response.statusCode}');
    }

    final document = parse(response.data);

    final title = document.querySelector("[itemprop='title']")?.text.trim() ??
        "${document.querySelector("#item-headline")?.querySelector("h2")?.text.trim() ?? "Brak tytułu"} - ${document.querySelector("#item-headline")?.querySelector("h3")?.text.trim()}";
    final desc =
        document.querySelector('p.description')?.text.trim() ?? 'Brak opisu';

    final info = document
        .querySelector('div.info')
        ?.text
        .replaceAll("\n", "")
        .replaceAll("\t", "")
        .replaceAll(" ", "");

    Match? yearMatch =
        RegExp(r'(Rok:(\d+))|(Premiera:(\d+))').firstMatch(info ?? "");

    String releaseDate = yearMatch?.group(2) ??
        yearMatch?.group(4) ??
        "Brak informacji o roku produkcji";

    String viewCount =
        RegExp(r'Odsłony:(\d+)').firstMatch(info ?? "")?.group(1) ??
            "Brak informacji o ilości odsłon";

    String country = RegExp(r'Kraj:(\w+)').firstMatch(info ?? "")?.group(1) ??
        "Brak informacji o kraju produkcji";

    final categories = document
        .querySelectorAll('ul.categories a')
        .map((cat) => cat.text.trim())
        .toList();

    final isSerialPage = document.querySelector('#links') == null;

    if (isSerialPage) {
      List<Season> seasons = [];
      document.querySelectorAll('#episode-list li').forEach((li) {
        final seasonTitle = li.querySelector('span')?.text.trim() ?? '';

        if (seasonTitle.isNotEmpty) {
          final season = Season(seasonTitle: seasonTitle, episodes: []);

          li.querySelectorAll('ul li').forEach((episode) {
            final episodeUrl =
                episode.querySelector('a')?.attributes['href'] ?? '';
            final episodeName = episode.querySelector('a')?.text.trim() ?? '';

            season.addEpisode(
                Episode(episodeName: episodeName, episodeUrl: episodeUrl));
          });

          seasons.add(season);
        }
      });

      return FilmDetails(
          title: title,
          desc: desc,
          releaseDate: releaseDate,
          viewCount: viewCount,
          country: country,
          categories: categories,
          isSerial: isSerialPage,
          seasons: seasons);
    } else {
      List<Link> links = [];

      document.querySelectorAll('tbody tr').forEach((row) {
        final main = row.querySelector('td')?.text.trim() ?? '';
        String link;

        try {
          Codec<String, String> stringToBase64 = utf8.fuse(base64);
          String decoded = stringToBase64.decode(
              (row.querySelector('td a')?.attributes['data-iframe'] ?? ''));
          link = jsonDecode(decoded)["src"] ?? '';
        } catch (error) {
          link = '';
        }

        final hostingImg =
            row.querySelector('td a img')?.attributes['src'] ?? '';
        final tableData = row.querySelectorAll('td');
        final language = tableData.length > 1 ? tableData[1].text.trim() : '';
        final qualityVersion =
            tableData.length > 2 ? tableData[2].text.trim() : '';

        links.add(Link(
          main: main,
          qualityVersion: qualityVersion,
          language: language,
          link: link,
          hostingImgUrl: hostingImg,
        ));
      });

      // return {
      //   'isSerialPage': isSerialPage,
      //   'releaseDate': releaseDate,
      //   'categories': categories,
      //   'viewCount': viewCount,
      //   'country': country,
      //   'desc': desc,
      //   'links': links,
      // };

      return FilmDetails(
          title: title,
          desc: desc,
          releaseDate: releaseDate,
          viewCount: viewCount,
          country: country,
          categories: categories,
          isSerial: isSerialPage,
          links: links);
    }
  }
}
