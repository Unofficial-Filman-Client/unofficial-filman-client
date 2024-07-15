import 'dart:async';

import 'package:flutter/material.dart';
import 'package:unofficial_filman_client/types/links.dart';
import 'package:unofficial_filman_client/utils/hosts.dart';

Future<List<Language>> _getAvailableLanguages(List<Link> links) async {
  List<Language> languages = [];
  for (Link link in links) {
    if (!languages.contains(link.language)) {
      languages.add(link.language);
    }
  }
  return languages;
}

Future<List<Quality>> _getAvaliableQualitiesForLanguage(
    Language lang, List<Link> links) async {
  List<Quality> qualities = [];
  for (Link link in links) {
    if (link.language == lang) {
      if (!qualities.contains(link.qualityVersion)) {
        qualities.add(link.qualityVersion);
      }
    }
  }
  qualities.sort();
  return qualities;
}

Future<dynamic> _showSelectionDialog(List items, BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Wybierz język'),
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
    List<Link> links, BuildContext context) async {
  final List<Language> languages = await _getAvailableLanguages(links);
  late Language lang;
  if (languages.length > 1 && context.mounted) {
    lang = await _showSelectionDialog(languages, context);
  } else if (languages.isNotEmpty) {
    lang = languages.first;
  } else {
    return null;
  }
  final List<Quality> qualities =
      await _getAvaliableQualitiesForLanguage(lang, links);
  late Quality quality;
  if (qualities.length > 1 && context.mounted) {
    quality = await _showSelectionDialog(qualities, context);
  } else if (qualities.isNotEmpty) {
    quality = qualities.first;
  } else {
    return null;
  }
  List<DirectLink> directs = await getDirects(links, lang, quality);
  return (directs..shuffle()).first;
}
