import "package:dio/dio.dart";
import "package:html/parser.dart";
import "package:unofficial_filman_client/types/links.dart";

// bool isSupportedHost(final Host host) {
//   return [
//     "streamtape",
//     "vidoza",
//     "vtube",
//   ].any((final String domain) => host.main.contains(domain));
// }

Future<List<DirectLink>> getDirects(final List<Host> links) async {
  final List<DirectLink> directLinks = [];
  for (Host link in links) {
    // if (link.language != lang || link.qualityVersion != quality) {
    //   continue;
    // }
    if (link.main.contains("streamtape")) {
      try {
        directLinks.add(DirectLink(
          link: await _scrapStreamtape(link.link),
          qualityVersion: link.qualityVersion,
          language: link.language,
        ));
      } catch (e) {
        //
      }
    }
    if (link.main.contains("vidoza")) {
      try {
        directLinks.add(DirectLink(
          link: await _scrapVidoza(link.link),
          qualityVersion: link.qualityVersion,
          language: link.language,
        ));
      } catch (e) {
        //
      }
    }
    if (link.main.contains("vtube")) {
      try {
        directLinks.add(DirectLink(
          link: await _scrapVtube(link.link),
          qualityVersion: link.qualityVersion,
          language: link.language,
        ));
      } catch (e) {
        //
      }
    }
  }
  return directLinks;
}

Future<String> _scrapVidoza(final String url) async {
  final Dio dio = Dio();
  try {
    final response = await dio.get(url);
    final document = parse(response.data);

    if (document.body?.text == "File was deleted") {
      throw Exception("File was deleted");
    }

    final link = document.querySelector("source")?.attributes["src"];

    if (link == null) {
      throw Exception("No link found");
    }

    return Uri.parse(link).toString();
  } catch (e) {
    throw Exception("Error scraping Vidoza.net: ${e.toString()}");
  }
}

Future<String> _scrapStreamtape(final String url) async {
  final Dio dio = Dio();

  try {
    final response = await dio.get(url);

    final jsLineMatch = RegExp(
            r"(?<=document\.getElementById\('botlink'\)\.innerHTML = )(.*)(?=;)")
        .firstMatch(response.data);

    if (jsLineMatch == null || jsLineMatch.group(0) == null) {
      throw Exception("No JS line found");
    }

    final String jsLine = jsLineMatch.group(0)!;

    final List<String> urls = RegExp(r"'([^']*)'")
        .allMatches(jsLine)
        .map((final m) => m.group(0)!.replaceAll("'", ""))
        .toList();

    if (urls.length != 2) {
      throw Exception("No URL in JS line");
    }

    final String base = urls[0];
    final String encoded = urls[1];

    final String fullUrl = "https:$base${encoded.substring(4)}";

    final apiResponse = await dio.get(
      fullUrl,
      options: Options(
        followRedirects: false,
        validateStatus: (final status) =>
            status != null && status >= 200 && status < 400,
      ),
    );

    final String? directLink = apiResponse.headers["location"]?.first;

    if (directLink == null) {
      throw Exception("No direct link found");
    }

    return directLink;
  } catch (e) {
    throw Exception("Error scraping Streamtape.com: ${e.toString()}");
  }
}

Future<String> _scrapVtube(final String url) async {
  final Dio dio = Dio();

  try {
    final response = await dio.get(url,
        options: Options(headers: {"referer": "https://filman.cc/"}));

    final jsLineMatch = RegExp(
            r"(?<=<script type='text\/javascript'>eval\()(.*)(?=\)<\/script>)")
        .firstMatch(response.data.toString().replaceAll("\n", ""));

    if (jsLineMatch == null || jsLineMatch.group(0) == null) {
      throw Exception("No JS line found");
    }

    final String jsLine = jsLineMatch.group(0)!;

    final removeStart = jsLine.replaceAll(
        "function(p,a,c,k,e,d){while(c--)if(k[c])p=p.replace(new RegExp('\\\\b'+c.toString(a)+'\\\\b','g'),k[c]);return p}(",
        "");

    final removeEnd = removeStart.substring(0, removeStart.length - 1);

    final firstArgMatch =
        RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'").firstMatch(removeEnd);

    if (firstArgMatch == null || firstArgMatch.group(0) == null) {
      throw Exception("No first arg found");
    }

    final firstArg = firstArgMatch.group(0)!;

    final stringWithoutFirstArg = removeEnd.replaceFirst(firstArg, "");

    final normalizedArgs =
        stringWithoutFirstArg.split(",").where((final i) => i.isNotEmpty);

    final int secondArg = int.parse(normalizedArgs.first);

    final int thirdArg = int.parse(normalizedArgs.elementAt(1));

    final fourthArg = normalizedArgs
        .elementAt(2)
        .replaceAll(".split('|')", "")
        .replaceAll("'", "")
        .split("|");

    String deobfuscate(String p, final int a, int c, final List<String> k) {
      while (c-- > 0) {
        if (k[c] != "") {
          p = p.replaceAll(RegExp("\\b${c.toRadixString(a)}\\b"), k[c]);
        }
      }
      return p;
    }

    final String decoded =
        deobfuscate(firstArg, secondArg, thirdArg, fourthArg);

    final directUrl = decoded
        .split("jwplayer(\"vplayer\").setup({sources:[{file:\"")[1]
        .split("\"")[0];

    return directUrl;
  } catch (e) {
    throw Exception("Error scraping Vtube.network: ${e.toString()}");
  }
}
