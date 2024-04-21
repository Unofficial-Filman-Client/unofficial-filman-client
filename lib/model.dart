import 'dart:collection';
import 'dart:convert';
import 'package:dio/dio.dart';
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

  Future<Response> loginToFilman(login, password) async {
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

      return response;
    } catch (identifier) {
      return Response(
        data: "<div class='alert'>${identifier.toString()}</div>",
        statusCode: 200,
        requestOptions: RequestOptions(path: ""),
      );
    }
  }

  Future<Response> getFilmanPage() async {
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
    return response;
  }

  Future<Response> searchInFilman(String query) async {
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
    return response;
  }

  Future<Map<String, dynamic>> getFilmDetails(String link) async {
    try {
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
        throw Exception(
            'GET $link redirect to ${response.headers['location']}');
      }

      if (response.statusCode != 200) {
        throw Exception('GET $link return ${response.statusCode}');
      }

      final document = parse(response.data);
      final desc = document.querySelector('p.description')?.text.trim() ?? '';

      final info = document
          .querySelector('div.info')
          ?.text
          .replaceAll("\n", "")
          .replaceAll("\t", "")
          .replaceAll(" ", "");

      Match? yearMatch = RegExp(r'Rok:(\d+)').firstMatch(info ?? "");

      String? releaseDate = "Brak informacji o roku produkcji";

      if (yearMatch != null) {
        releaseDate = yearMatch.group(1);
      }

      Match? viewCountMatch = RegExp(r'Odsłony:(\d+)').firstMatch(info ?? "");

      String? viewCount = "Brak informacji o ilości odsłon";

      if (viewCountMatch != null) {
        viewCount = viewCountMatch.group(1);
      }

      Match? countryMatch = RegExp(r'Kraj:(\w+)').firstMatch(info ?? "");

      String? country = "Brak informacji o kraju produkcji";

      if (countryMatch != null) {
        country = countryMatch.group(1);
      }

      final categories = document
          .querySelectorAll('ul.categories a')
          .map((cat) => cat.text.trim())
          .toList();

      final isSerialPage = document.querySelector('#links') == null;
      final season = <Map<String, dynamic>>[];

      if (isSerialPage) {
        document.querySelectorAll('#episode-list li').forEach((li) {
          final seasonTitle = li.querySelector('span')?.text.trim() ?? '';

          if (seasonTitle.isNotEmpty) {
            final episodes = <Map<String, String>>[];

            li.querySelectorAll('ul li').forEach((episode) {
              final episodeUrl =
                  episode.querySelector('a')?.attributes['href'] ?? '';
              final episodeName = episode.querySelector('a')?.text.trim() ?? '';

              episodes.add({
                'url': episodeUrl,
                'name': episodeName,
              });
            });

            season.add({
              'name': seasonTitle,
              'episodes': episodes,
            });
          }
        });

        return {
          'isSerialPage': isSerialPage,
          'releaseDate': releaseDate,
          'categories': categories,
          'viewCount': viewCount,
          'country': country,
          'desc': desc,
          'season': season,
        };
      } else {
        final links = <Map<String, String>>[];

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

          final linkObj = {
            'main': main,
            'link': link,
            'language': language,
            'qualityVersion': qualityVersion,
            'hostingImg': hostingImg,
          };

          links.add(linkObj);
        });

        return {
          'isSerialPage': isSerialPage,
          'releaseDate': releaseDate,
          'categories': categories,
          'viewCount': viewCount,
          'country': country,
          'desc': desc,
          'links': links,
        };
      }
    } catch (error) {
      throw Exception('Error occurred while fetching video details: $error');
    }
  }
}
