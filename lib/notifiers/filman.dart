import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:unofficial_filman_client/types/exceptions.dart';
import 'package:unofficial_filman_client/types/film.dart';
import 'package:unofficial_filman_client/types/film_details.dart';
import 'package:unofficial_filman_client/types/home_page.dart';
import 'package:unofficial_filman_client/types/auth_response.dart';
import 'package:unofficial_filman_client/types/links.dart';
import 'package:unofficial_filman_client/types/search_results.dart';
import 'package:unofficial_filman_client/types/season.dart';
import 'package:unofficial_filman_client/types/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart';

class FilmanNotifier extends ChangeNotifier {
  final List<String> cookies = [];

  late final SharedPreferences prefs;
  late final Dio dio;
  User? user;
  late final FlutterSecureStorage secureStorage;

  Future<void> initPrefs() async {
    dio = Dio();
    prefs = await SharedPreferences.getInstance();
    cookies.addAll(prefs.getStringList('cookies') ?? []);

    secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true));

    final login = await secureStorage.read(key: 'login');
    final password = await secureStorage.read(key: 'password');

    if (login != null && password != null) {
      user = User(login: login, password: password);
    }
  }

  void saveUser(String login, String password) {
    secureStorage.write(key: 'login', value: login);
    secureStorage.write(key: 'password', value: password);
    user = User(login: login, password: password);
  }

  void logout() {
    cookies.clear();
    prefs.remove('cookies');
  }

  Future<AuthResponse> createAccountOnFilmn(String login, String email,
      String password, String password2, String recaptchatoken) async {
    try {
      final response = await dio.post(
        "https://filman.cc/rejestracja",
        data: {
          'login': login,
          'email': email,
          'password': password,
          'password2': password2,
          'g-recaptcha-response': recaptchatoken,
          'submit': '',
        },
        options: Options(
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            followRedirects: false,
            validateStatus: (status) {
              return true;
            }),
      );
      final registerResponse =
          AuthResponse(success: response.statusCode == 302);
      final document = parse(response.data);
      document.querySelectorAll(".alert div").forEach((element) {
        final error = element.text.trim();
        if (error.isNotEmpty) {
          registerResponse.addError(error);
        }
      });
      if (registerResponse.errors.isEmpty) {
        document.querySelectorAll(".alert").forEach((element) {
          final error = element.text.trim();
          if (error.isNotEmpty) {
            registerResponse.addError(error);
          }
        });
      }
      return registerResponse;
    } catch (e) {
      final registerResponse = AuthResponse(success: false);
      registerResponse.addError('Error occurred while registering: $e');
      return registerResponse;
    }
  }

  Future<AuthResponse> loginToFilman(String login, String password) async {
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
        prefs.setStringList('cookies', cookies);
      }

      AuthResponse loginResponse =
          AuthResponse(success: response.statusCode == 302);

      final document = parse(response.data);

      document.querySelectorAll('.alert').forEach((element) {
        final error = element.text.trim();
        if (error.isNotEmpty) {
          loginResponse.addError(error);
        }
      });

      return loginResponse;
    } catch (identifier) {
      AuthResponse loginResponse = AuthResponse(success: false);
      loginResponse.addError('Error occurred while logging in: $identifier');
      return loginResponse;
    }
  }

  Future<HomePageResponse> getFilmanPage() async {
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
      if (response.headers['location']
              ?.contains("https://filman.cc/logowanie") ==
          true) {
        logout();
        throw const LogOutException();
      }
    }

    final document = parse(response.data);

    final homePage = HomePageResponse();

    for (final list in document.querySelectorAll('div[id=item-list]')) {
      for (final filmDOM in list.children) {
        final poster = filmDOM.querySelector('.poster');
        final String title =
            poster?.querySelector('a')?.attributes['title']?.trim() ??
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
            Film(title: title, desc: "", imageUrl: imageUrl, link: link));
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

    if (response.headers['location'] != null) {
      if (response.headers['location']
              ?.contains("https://filman.cc/logowanie") ==
          true) {
        logout();
        throw const LogOutException();
      }
    }

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
      if (response.headers['location']
              ?.contains("https://filman.cc/logowanie") ==
          true) {
        logout();
        throw const LogOutException();
      }
    }

    final document = parse(response.data);

    final title = document.querySelector("[itemprop='title']")?.text.trim() ??
        document
            .querySelector("#item-headline")
            ?.querySelector("h2")
            ?.text
            .trim() ??
        "Brak tytułu";

    final desc =
        document.querySelector('p.description')?.text.trim() ?? 'Brak opisu';

    final info = document
        .querySelector('div.info')
        ?.text
        .replaceAll("\n", "")
        .replaceAll("\t", "")
        .replaceAll(" ", "");

    final imageUrl = document
            .querySelector("#single-poster")
            ?.querySelector("img")
            ?.attributes["src"] ??
        '';

    Match? yearMatch =
        RegExp(r'(Rok:(\d+))|(Premiera:(\d+))').firstMatch(info ?? "");

    String releaseDate = yearMatch?.group(2) ??
        yearMatch?.group(4) ??
        "Brak informacji o roku produkcji";

    String viewCount =
        RegExp(r'Odsłony:(\d+)').firstMatch(info ?? "")?.group(1) ??
            "Brak informacji o ilości odsłon";

    String? countries = RegExp(r'Kraj:(\w+)').firstMatch(info ?? "")?.group(1);

    String country = countries != null
        ? RegExp(r'(?:[A-Z]+|^)[a-z]*')
            .allMatches(countries)
            .map((e) => e.group(0))
            .join(", ")
        : "Brak informacji o kraju produkcji";

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
          url: link,
          title: title,
          desc: desc,
          imageUrl: imageUrl,
          releaseDate: releaseDate,
          viewCount: viewCount,
          country: country,
          categories: categories,
          isSerial: isSerialPage,
          seasons: seasons,
          isEpisode: false);
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
          language: language.replaceAll("Napisy_Tansl", "Napisy_Transl"),
          link: link,
          hostingImgUrl: hostingImg,
        ));
      });

      final isEpisode =
          document.querySelector("#item-headline")?.querySelector("h3") != null;

      if (isEpisode) {
        final seasonEpisodeTag = document
            .querySelector("#item-headline")
            ?.querySelector("h3")
            ?.text
            .trim();

        final nextEpisodeUrl = document
            .querySelector("#item-info")
            ?.querySelectorAll("a")
            .firstWhere(
              (el) => el.text.trim() == 'Następny',
            )
            .attributes['href']
            ?.replaceAll("#single-poster", "");

        final prevEpisodeUrl = document
            .querySelector("#item-info")
            ?.querySelectorAll("a")
            .firstWhere(
              (el) => el.text.trim() == 'Następny',
            )
            .attributes['href']
            ?.replaceAll("#single-poster", "");

        final parentUrl = document
            .querySelector("#single-poster")
            ?.querySelector("a")
            ?.attributes["href"];

        return FilmDetails(
            url: link,
            title: title,
            desc: desc,
            imageUrl: imageUrl,
            releaseDate: releaseDate,
            viewCount: viewCount,
            country: country,
            categories: categories,
            isSerial: isSerialPage,
            links: links,
            seasonEpisodeTag: seasonEpisodeTag,
            parentUrl: parentUrl,
            prevEpisodeUrl: prevEpisodeUrl,
            nextEpisodeUrl: nextEpisodeUrl,
            isEpisode: isEpisode);
      }

      return FilmDetails(
          url: link,
          title: title,
          desc: desc,
          imageUrl: imageUrl,
          releaseDate: releaseDate,
          viewCount: viewCount,
          country: country,
          categories: categories,
          isSerial: isSerialPage,
          links: links,
          isEpisode: isEpisode);
    }
  }
}
