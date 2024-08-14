import "dart:async";

import "package:flutter/material.dart";
import "package:unofficial_filman_client/types/links.dart";
import "package:unofficial_filman_client/utils/hosts.dart";

Future<List<Language>> _getAvailableLanguages(final List<Host> links) async {
  final List<Language> languages = [];
  for (Host link in links) {
    if (!languages.contains(link.language) && isSupportedHost(link)) {
      languages.add(link.language);
    }
  }
  return languages;
}

Future<List<Quality>> _getAvaliableQualitiesForLanguage(
    final Language lang, final List<Host> links) async {
  final List<Quality> qualities = [];
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
    final BuildContext context, final List items, final String title) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (final context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map((final item) => ListTile(
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

Future<(Language?, Quality?)> getUserSelectedPreferences(
    final List<Host> links, final BuildContext context) async {
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
    return (null, null);
  }
  final List<Quality> qualities =
      await _getAvaliableQualitiesForLanguage(lang, links);
  late Quality quality;
  if (qualities.length > 1 && context.mounted) {
    quality = await _showSelectionDialog(context, qualities, "Wybierz jakość");
  } else if (qualities.isNotEmpty) {
    quality = qualities.first;
  } else {
    return (lang, null);
  }
  return (lang, quality);
}

Future<DirectLink?> getUserSelectedVersion(
    final List<Host> links, final BuildContext context) async {
  final (lang, quality) = await getUserSelectedPreferences(links, context);
  if (lang == null || quality == null) {
    return null;
  }
  final List<DirectLink> directs = await getDirects(links, lang, quality);
  return (directs..shuffle()).first;
}
