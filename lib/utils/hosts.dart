import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:unofficial_filman_client/types/links.dart';

Future<List<DirectLink>> getDirects(
    List<Link> links, Language lang, Quality quality) async {
  List<DirectLink> directLinks = [];
  for (Link link in links) {
    if (link.language != lang || link.qualityVersion != quality) {
      continue;
    }
    if (link.main.toString().contains("streamtape")) {
      directLinks.add(DirectLink(
        link: await _scrapStreamtape(link.link),
        qualityVersion: link.qualityVersion,
        language: link.language,
      ));
    }
    if (link.main.toString().contains("vidoza")) {
      directLinks.add(DirectLink(
        link: await _scrapVidoza(link.link),
        qualityVersion: link.qualityVersion,
        language: link.language,
      ));
    }
  }
  return directLinks;
}

Future<String> _scrapVidoza(String url) async {
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

Future<String> _scrapStreamtape(String url) async {
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
