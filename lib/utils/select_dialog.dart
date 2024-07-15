import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unofficial_filman_client/types/links.dart';
import 'package:unofficial_filman_client/utils/hosts.dart';

Future<List<Language>> _getAvailableLanguages(List<Host> links) async {
  List<Language> languages = [];
  for (Host link in links) {
    if (!languages.contains(link.language) && isSupportedHost(link)) {
      languages.add(link.language);
    }
  }
  return languages;
}

Future<List<Quality>> _getAvaliableQualitiesForLanguage(
    Language lang, List<Host> links) async {
  List<Quality> qualities = [];
  for (Host link in links) {
    if (link.language == lang) {
      if (!qualities.contains(link.qualityVersion) && isSupportedHost(link)) {
        qualities.add(link.qualityVersion);
      }
    }
  }
  qualities.sort();
  return qualities;
}

Future<dynamic> _showSelectionDialog(
    BuildContext context, List items, String title) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((item) => ListTile(
                  title: Text(item.toString()),
                  onTap: () {
                    Navigator.pop(context, item);
                  },
                ))
            .toList(),
      ),
    ),
  );
}

Future<DirectLink?> getUserSelectedVersion(
    List<Host> links, BuildContext context) async {
  final List<Language> languages = await _getAvailableLanguages(links);
  late Language lang;
  if (languages.length > 1 && context.mounted) {
    lang = await _showSelectionDialog(
      context,
      languages,
      "Wybierz język",
    );
  } else if (languages.isNotEmpty) {
    lang = languages.first;
  } else {
    return null;
  }
  final List<Quality> qualities =
      await _getAvaliableQualitiesForLanguage(lang, links);
  late Quality quality;
  if (qualities.length > 1 && context.mounted) {
    quality = await _showSelectionDialog(context, qualities, "Wybierz jakość");
  } else if (qualities.isNotEmpty) {
    quality = qualities.first;
  } else {
    return null;
  }
  List<DirectLink> directs = await getDirects(links, lang, quality);
  return (directs..shuffle()).first;
}
