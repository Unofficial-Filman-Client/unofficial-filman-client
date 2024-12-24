import "dart:async";

import "package:flutter/material.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";

Future<List<Language>> _getAvailableLanguages(
    final List<MediaLink> links) async {
  final List<Language> languages = [];
  for (final link in links) {
    if (!languages.contains(link.language)) {
      languages.add(link.language);
    }
  }
  languages.sort();
  return languages;
}

Future<List<Quality>> _getAvaliableQualitiesForLanguage(
    final Language lang, final List<MediaLink> links) async {
  final List<Quality> qualities = [];
  for (final link in links) {
    if (link.language == lang) {
      if (!qualities.contains(link.quality)) {
        qualities.add(link.quality);
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
    final BuildContext context, final List<MediaLink> directs,
    [final bool supportm3u8 = true]) async {
  directs
      .removeWhere((final link) => link.url.contains(".m3u8") && !supportm3u8);

  final List<Language> languages = await _getAvailableLanguages(directs);
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
      await _getAvaliableQualitiesForLanguage(lang, directs);
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

// TODO: if need add m3u8 support here
Future<MediaLink?> selectBestLink(final List<MediaLink> links) async {
  final validLinks = <MediaLink>[];

  for (final link in links) {
    await link.getDirectLink();
    if (link.isVideoValid) {
      validLinks.add(link);
    }
  }

  if (validLinks.isEmpty) return null;

  validLinks
      .sort((final a, final b) => a.responseTime.compareTo(b.responseTime));

  return validLinks.first;
}

Future<MediaLink?> getUserSelectedVersion(
    final BuildContext context, final List<MediaLink> links) async {
  // links.removeWhere((final link) => link.url.contains(".m3u8") && !supportm3u8);
  if (!context.mounted) return null;
  final (lang, quality) = await getUserSelectedPreferences(context, links);
  if (lang == null || quality == null) {
    return null;
  }
  links.removeWhere(
      (final link) => link.language != lang || link.quality != quality);
  return await selectBestLink(links);
}
