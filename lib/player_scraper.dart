import 'package:dio/dio.dart';
import 'package:html/parser.dart';

Future<String> getDirect(List<dynamic> links) async {
  for (var link in links) {
    if (link["main"].toString().contains("vidoza")) {
      return await scrapVidoza(link["link"]);
    }
  }
  return '';
}

Future<String> scrapVidoza(String url) async {
  final Dio dio = Dio();
  final response = await dio.get(url);
  final document = parse(response.data);

  final link = document.querySelector('source')?.attributes['src'];

  return Uri.parse(link ?? '').toString();
}
