import "dart:async";
import "dart:math";
import "package:dio/dio.dart";
import "package:html/parser.dart";
import "package:unofficial_filman_client/types/exceptions.dart";

String getBaseUrl(final String url) {
  final uri = Uri.parse(url);
  return "${uri.scheme}://${uri.host}";
}

abstract class VideoScraper {
  final String url;

  VideoScraper(this.url);

  Future<String> getVideoLink();
}

enum Language implements Comparable {
  pl("PL"),
  dubbing("Dubbing"),
  lektor("Lektor"),
  dubbingKino("Dubbing_Kino"),
  lektorIVO("Lektor_IVO"),
  napisy("Napisy"),
  napisyTansl("Napisy_Tansl"),
  eng("ENG");

  const Language(this.language);
  final String language;

  @override
  int compareTo(final other) {
    return Language.values
        .indexOf(this)
        .compareTo(Language.values.indexOf(other));
  }

  @override
  String toString() => language;
}

enum Quality implements Comparable {
  p1080("1080p"),
  p720("720p"),
  p480("480p"),
  p360("360p");

  const Quality(this.quality);
  final String quality;

  @override
  int compareTo(final other) {
    return Quality.values
        .indexOf(this)
        .compareTo(Quality.values.indexOf(other));
  }

  @override
  String toString() => quality;
}

class StreamtapeScraper extends VideoScraper {
  StreamtapeScraper(super.url);

  @override
  Future<String> getVideoLink() async {
    final Dio dio = Dio();
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

    return Uri.parse(directLink).toString();
  }

  static bool isSupported(final String url) {
    return url.contains("streamtape");
  }
}

class VidozaScraper extends VideoScraper {
  VidozaScraper(super.url);

  @override
  Future<String> getVideoLink() async {
    final Dio dio = Dio();
    final response = await dio.get(url);
    final document = parse(response.data);

    if (document.body?.text == "File was deleted") {
      throw const NoSourcesException();
    }

    final directLink = document.querySelector("source")?.attributes["src"];

    if (directLink == null) {
      throw const NoSourcesException();
    }

    return Uri.parse(directLink).toString();
  }

  static bool isSupported(final String url) {
    return url.contains("vidoza");
  }
}

// class VtubeScraper extends VideoScraper {
//   VtubeScraper(super.url);

//   String deobfuscate(String p, final int a, int c, final List<String> k) {
//     while (c-- > 0) {
//       if (k[c] != "") {
//         p = p.replaceAll(RegExp("\\b${c.toRadixString(a)}\\b"), k[c]);
//       }
//     }
//     return p;
//   }

//   @override
//   Future<String> getVideoLink() async {
//     final Dio dio = Dio();
//     final response = await dio.get(url,
//         options: Options(headers: {"referer": "https://filman.cc/"}));

//     final jsLineMatch = RegExp(
//             r"(?<=<script type='text\/javascript'>eval\()(.*)(?=\)<\/script>)")
//         .firstMatch(response.data.toString().replaceAll("\n", ""));

//     if (jsLineMatch == null || jsLineMatch.group(0) == null) {
//       throw const NoSourcesException();
//     }

//     final String jsLine = jsLineMatch.group(0)!;

//     final removeStart = jsLine.replaceAll(
//         "function(p,a,c,k,e,d){while(c--)if(k[c])p=p.replace(new RegExp('\\\\b'+c.toString(a)+'\\\\b','g'),k[c]);return p}(",
//         "");

//     final removeEnd = removeStart.substring(0, removeStart.length - 1);

//     final firstArgMatch =
//         RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'").firstMatch(removeEnd);

//     if (firstArgMatch == null || firstArgMatch.group(0) == null) {
//       throw const NoSourcesException();
//     }

//     final firstArg = firstArgMatch.group(0)!;

//     final stringWithoutFirstArg = removeEnd.replaceFirst(firstArg, "");

//     final normalizedArgs =
//         stringWithoutFirstArg.split(",").where((final i) => i.isNotEmpty);

//     final int secondArg = int.parse(normalizedArgs.first);

//     final int thirdArg = int.parse(normalizedArgs.elementAt(1));

//     final fourthArg = normalizedArgs
//         .elementAt(2)
//         .replaceAll(".split('|')", "")
//         .replaceAll("'", "")
//         .split("|");

//     final String decoded =
//         deobfuscate(firstArg, secondArg, thirdArg, fourthArg);

//     final directLink = decoded
//         .split("jwplayer(\"vplayer\").setup({sources:[{file:\"")[1]
//         .split("\"")[0];

//     return Uri.parse(directLink).toString();
//   }

//   static bool isSupported(final String url) {
//     return url.contains("vtube");
//   }
// }

class DoodStreamScraper extends VideoScraper {
  DoodStreamScraper(super.url);

  @override
  Future<String> getVideoLink() async {
    final Dio dio = Dio();

    final embedUrl = url.replaceAll("/d/", "/e/");
    final response = await dio.get(embedUrl);

    final host = getBaseUrl(response.redirects.last.location.toString());

    final responseText = response.data;

    final md5Match = RegExp(r"/pass_md5/[^']*").firstMatch(responseText);
    if (md5Match == null) {
      throw Exception("pass_md5 not found");
    }

    final md5 = host + md5Match.group(0)!;

    final trueResponse = await dio.get(md5,
        options: Options(
          headers: {
            "Referer": host,
          },
          validateStatus: (final _) => true,
        ));

    final trueUrl = trueResponse.data +
        _createHashTable() +
        "?token=" +
        md5.split("/").last;

    return Uri.parse(trueUrl).toString();
  }

  String _createHashTable() {
    const alphabet =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    final random = Random();
    return List.generate(
        10, (final _) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  static bool isSupported(final String url) {
    final urls = [
      "https://d0000d.com",
      "https://d000d.com",
      "https://doodstream.com",
      "https://dooood.com",
      "https://dood.wf",
      "https://dood.cx",
      "https://dood.sh",
      "https://dood.watch",
      "https://dood.pm",
      "https://dood.to",
      "https://dood.so",
      "https://dood.ws",
      "https://dood.yt",
      "https://dood.li",
      "https://ds2play.com",
      "https://ds2video.com"
    ];
    return urls.any((final u) => url.contains(u));
  }
}

class ScraperFactory {
  static VideoScraper getScraper(final String url) {
    if (StreamtapeScraper.isSupported(url)) {
      return StreamtapeScraper(url);
    } else if (VidozaScraper.isSupported(url)) {
      return VidozaScraper(url);
      // } else if (VtubeScraper.isSupported(url)) { // m3u8
      //   return VtubeScraper(url);
    } else if (DoodStreamScraper.isSupported(url)) {
      return DoodStreamScraper(url);
    } else {
      throw Exception("Unsupported host: $url");
    }
  }
}

class MediaLink {
  final String url;
  final Language language;
  final Quality quality;
  late final VideoScraper _scraper;

  String? _directVideoUrl;
  bool _isVideoValid = false;
  int _responseTime = 0;

  MediaLink(this.url, final String language, final String quality)
      : language = Language.values
            .firstWhere((final lang) => lang.language == language),
        quality =
            Quality.values.firstWhere((final qual) => qual.quality == quality),
        _scraper = ScraperFactory.getScraper(url);

  MediaLink.fromMap(final Map<String, dynamic> map)
      : url = map["url"] as String,
        language = Language.values
            .firstWhere((final lang) => lang.language == map["language"]),
        quality = Quality.values
            .firstWhere((final qual) => qual.quality == map["quality"]),
        _scraper = ScraperFactory.getScraper(map["url"] as String);

  Map<String, dynamic> toMap() {
    return {
      "url": url,
      "language": language.language,
      "quality": quality.quality,
    };
  }

  Future<String?> getDirectLink() async {
    if (_directVideoUrl != null) {
      return _directVideoUrl;
    }

    try {
      _directVideoUrl = await _scraper.getVideoLink();

      await verifyDirectVideoUrl();
    } catch (e) {
      _directVideoUrl = null;
      _isVideoValid = false;
    }

    return _directVideoUrl;
  }

  Future<void> verifyDirectVideoUrl() async {
    if (_directVideoUrl == null) return;

    try {
      final stopwatch = Stopwatch()..start();
      final response = await Dio().head(
        _directVideoUrl!,
        options: Options(
            followRedirects: true, headers: {"referer": getBaseUrl(url)}),
      );
      stopwatch.stop();
      _isVideoValid = response.statusCode == 200 &&
          response.headers.value("content-type")?.contains("video") == true;
      _responseTime = stopwatch.elapsedMilliseconds;
    } catch (_) {
      _isVideoValid = false;
    }
  }

  bool get isVideoValid => _isVideoValid;
  int get responseTime => _responseTime;

  @override
  String toString() =>
      "MediaLink(url: $url, language: $language, quality: $quality, responseTime: $responseTime, directVideoUrl: $_directVideoUrl, isVideoValid: $_isVideoValid)";
}
