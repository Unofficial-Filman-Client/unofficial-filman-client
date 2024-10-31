import "dart:convert";
import "package:dio/dio.dart";
import "package:html/dom.dart" as dom;
import "package:unofficial_filman_client/types/exceptions.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/home_page.dart";
import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/types/search_results.dart";
import "package:unofficial_filman_client/types/season.dart";
import "package:unofficial_filman_client/types/user.dart";
import "package:flutter/material.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:html/parser.dart";
import "package:dio_cache_interceptor/dio_cache_interceptor.dart";

class FilmanNotifier extends ChangeNotifier {
  final List<String> cookies = [];
  late final SharedPreferences prefs;
  late final Dio dio;
  User? user;
  late final FlutterSecureStorage secureStorage;

  Future<void> initPrefs() async {
    dio = Dio();
    dio.interceptors.add(CfWrapperInterceptor());
    dio.interceptors.add(DioCacheInterceptor(
        options: CacheOptions(
      store: MemCacheStore(maxSize: 10485760, maxEntrySize: 1048576),
      policy: CachePolicy.request,
    )));
    prefs = await SharedPreferences.getInstance();
    cookies.addAll(prefs.getStringList("cookies") ?? []);
    secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    final login = await secureStorage.read(key: "login");

    if (login != null) {
      user = User(login: login);
    }
  }

  void saveUser(final String login) {
    secureStorage.write(key: "login", value: login);
    user = User(login: login);
  }

  void logout() {
    cookies.clear();
    prefs.remove("cookies");
  }

  Options _buildDioOptions({required final String contentType}) {
    return Options(
      headers: {"Content-Type": contentType, "cookie": cookies.join("; ")},
      followRedirects: false,
      validateStatus: (final status) => true,
    );
  }

  // Future<AuthResponse> createAccountOnFilmn(
  //     final String login,
  //     final String email,
  //     final String password,
  //     final String password2,
  //     final String recaptchatoken) async {
  //   try {
  //     final response = await dio.post(
  //       "https://filman.cc/rejestracja",
  //       data: {
  //         "login": login,
  //         "email": email,
  //         "password": password,
  //         "password2": password2,
  //         "g-recaptcha-response": recaptchatoken,
  //         "submit": "",
  //       },
  //       options:
  //           _buildDioOptions(contentType: "application/x-www-form-urlencoded"),
  //     );

  //     final registerResponse =
  //         AuthResponse(success: response.statusCode == 302);
  //     final document = parse(response.data);

  //     document.querySelectorAll(".alert div").forEach((final element) {
  //       final error = element.text.trim();
  //       if (error.isNotEmpty) {
  //         registerResponse.addError(error);
  //       }
  //     });

  //     if (registerResponse.errors.isEmpty) {
  //       document.querySelectorAll(".alert").forEach((final element) {
  //         final error = element.text.trim();
  //         if (error.isNotEmpty) {
  //           registerResponse.addError(error);
  //         }
  //       });
  //     }

  //     return registerResponse;
  //   } catch (e) {
  //     return AuthResponse(success: false)
  //       ..addError("Error occurred while registering: $e");
  //   }
  // }

  // Future<AuthResponse> loginToFilman(
  //   final String login,
  //   final String password, {
  //   final String? captchaToken,
  // }) async {
  //   try {
  //     final response = await dio.post(
  //       "https://filman.cc/logowanie",
  //       data: {
  //         "login": login,
  //         "password": password,
  //         "submit": "",
  //         if (captchaToken != null) "g-recaptcha-response": captchaToken,
  //       },
  //       options:
  //           _buildDioOptions(contentType: "application/x-www-form-urlencoded"),
  //     );

  //     final cookiesHeader = response.headers["set-cookie"];
  //     if (cookiesHeader != null) {
  //       cookies
  //         ..clear()
  //         ..addAll(cookiesHeader);
  //       prefs.setStringList("cookies", cookies);
  //     }

  //     final loginResponse = AuthResponse(success: response.statusCode == 302);
  //     final document = parse(response.data);

  //     document.querySelectorAll(".alert").forEach((final element) {
  //       final error = element.text.trim();
  //       if (error.isNotEmpty) {
  //         loginResponse.addError(error);
  //       }
  //     });

  //     return loginResponse;
  //   } catch (e) {
  //     return AuthResponse(success: false)
  //       ..addError("Error occurred while logging in: $e");
  //   }
  // }

  Future<HomePageResponse> getFilmanPage() async {
    final response = await dio.get(
      "https://filman.cc/",
      options: _buildDioOptions(contentType: "application/json"),
    );

    if (response.headers["location"]?.contains("https://filman.cc/logowanie") ??
        false) {
      logout();
      throw const LogOutException();
    }

    final document = parse(response.data);
    final homePage = HomePageResponse();

    for (final list in document.querySelectorAll("div[id=item-list]")) {
      for (final filmDOM in list.children) {
        final poster = filmDOM.querySelector(".poster");
        final title = poster?.querySelector("a")?.attributes["title"]?.trim() ??
            "Brak danych";
        final imageUrl = poster?.querySelector("img")?.attributes["src"] ??
            "https://placehold.co/250x370?font=roboto&text=?";
        final link =
            poster?.querySelector("a")?.attributes["href"] ?? "Brak danych";
        final category =
            list.parent?.querySelector("h3")?.text.trim() ?? "INNE";

        homePage.addFilm(
            category, Film(title: title, imageUrl: imageUrl, link: link));
      }
    }

    return homePage;
  }

  Future<SearchResults> searchInFilman(final String query) async {
    final response = await dio.get(
      "https://filman.cc/item",
      queryParameters: {"phrase": query},
      options: _buildDioOptions(contentType: "application/json"),
    );

    if (response.headers["location"]?.contains("https://filman.cc/logowanie") ??
        false) {
      logout();
      throw const LogOutException();
    }

    final document = parse(response.data);
    final searchResults = SearchResults();

    document
        .querySelectorAll(".col-xs-6.col-sm-3.col-lg-2")
        .forEach((final filmDOM) {
      final poster = filmDOM.querySelector(".poster");
      final title =
          filmDOM.querySelector(".film_title")?.text.trim() ?? "Brak danych";
      final desc =
          poster?.querySelector("a")?.attributes["data-text"]?.trim() ??
              "Brak danych";
      final imageUrl =
          poster?.querySelector("img")?.attributes["src"]?.trim() ??
              "https://placehold.co/250x370?font=roboto&text=?";
      final link =
          poster?.querySelector("a")?.attributes["href"] ?? "Brak danych";

      searchResults.addFilm(
          Film(title: title, desc: desc, imageUrl: imageUrl, link: link));
    });

    return searchResults;
  }

  Future<FilmDetails> getFilmDetails(final String link) async {
    final response = await dio.get(
      link,
      options: _buildDioOptions(contentType: "application/json"),
    );

    if (response.headers["location"]?.contains("https://filman.cc/logowanie") ==
        true) {
      logout();
      throw const LogOutException();
    }

    final document = parse(response.data);
    final title = document.querySelector("[itemprop='title']")?.text.trim() ??
        document.querySelector("#item-headline h2")?.text.trim() ??
        "Brak tytułu";
    final desc =
        document.querySelector("p.description")?.text.trim() ?? "Brak opisu";
    final info = document
            .querySelector("div.info")
            ?.text
            .replaceAll(RegExp(r"\s+"), "") ??
        "";
    final imageUrl =
        document.querySelector("#single-poster img")?.attributes["src"] ??
            "https://placehold.co/250x370?font=roboto&text=?";
    final releaseDate = RegExp(r"(Rok:(\d+))|(Premiera:(\d+))")
            .firstMatch(info)
            ?.group(2) ??
        RegExp(r"(Rok:(\d+))|(Premiera:(\d+))").firstMatch(info)?.group(4) ??
        "Brak informacji o roku produkcji";
    final viewCount = RegExp(r"Odsłony:(\d+)").firstMatch(info)?.group(1) ??
        "Brak informacji o ilości odsłon";
    String country = document
        .querySelectorAll("ul.country a")
        .map((final can) => can.text.trim())
        .join(", ");

    if (country.isEmpty) {
      country = "Brak informacji o kraju produkcji";
    }

    final categories = document
        .querySelectorAll("ul.categories a")
        .map((final cat) => cat.text.trim())
        .toList();
    final isSerialPage = document.querySelector("#links") == null;

    if (isSerialPage) {
      final List<Season> seasons = [];
      document.querySelectorAll("#episode-list li").forEach((final li) {
        final seasonTitle = li.querySelector("span")?.text.trim() ?? "";
        if (seasonTitle.isNotEmpty) {
          final season = Season(seasonTitle: seasonTitle, episodes: []);
          li.querySelectorAll("ul li").forEach((final episode) {
            final episodeUrl =
                episode.querySelector("a")?.attributes["href"] ?? "";
            final episodeName = episode.querySelector("a")?.text.trim() ?? "";
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
        isEpisode: false,
      );
    } else {
      final List<Host> links = [];

      document.querySelectorAll("tbody tr").forEach((final row) {
        final main = row.querySelector("td")?.text.trim() ?? "";
        String? link;

        try {
          final decoded = base64Decode(
              row.querySelector("td a")?.attributes["data-iframe"] ?? "");
          link = (jsonDecode(utf8.decode(decoded))["src"] as String)
              .split("/")
              .take(7)
              .join("/");
        } catch (_) {
          link = null;
        }

        if (link == null || link.isEmpty == true) return;

        final tableData = row.querySelectorAll("td");
        if (tableData.length < 3) return;
        final language = tableData[1].text.trim();
        final qualityVersion = tableData[2].text.trim();

        links.add(Host(
            main: main,
            qualityVersion: qualityVersion,
            language: language,
            link: link));
      });

      final isEpisode = document.querySelector("#item-headline h3") != null;
      if (isEpisode) {
        final seasonEpisodeTag =
            document.querySelector("#item-headline h3")?.text.trim();
        final nextEpisodeUrl = document
            .querySelectorAll("#item-info a")
            .firstWhere(
              (final el) => el.text.trim() == "Następny",
              orElse: () => dom.Element.tag("a")..attributes["href"] = "",
            )
            .attributes["href"]
            ?.replaceAll("#single-poster", "");
        final prevEpisodeUrl = document
            .querySelectorAll("#item-info a")
            .firstWhere(
              (final el) => el.text.trim() == "Następny",
              orElse: () => dom.Element.tag("a")..attributes["href"] = "",
            )
            .attributes["href"]
            ?.replaceAll("#single-poster", "");
        final parentUrl =
            document.querySelector("#single-poster a")?.attributes["href"];

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
          isEpisode: isEpisode,
        );
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
        isEpisode: isEpisode,
      );
    }
  }
}
