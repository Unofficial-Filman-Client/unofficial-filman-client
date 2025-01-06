import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";
import "package:unofficial_filman_client/utils/navigation_service.dart";

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

Future<dynamic> _showSelectionDialog(final List items, final String title) {
  return showDialog(
    context: NavigationService.navigatorKey.currentContext!,
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
  final List<MediaLink> directs,
  /*[final bool supportm3u8 = true]*/
) async {
  final context = NavigationService.navigatorKey.currentContext!;
  // directs.removeWhere((final link) => link.url.contains(".m3u8") && !supportm3u8);

  final List<Language> languages = await _getAvailableLanguages(directs);
  late Language lang;
  if (languages.length > 1 && context.mounted) {
    if (Provider.of<SettingsNotifier>(context, listen: false).autoLanguage) {
      final List<Language> preferredLanguages =
          Provider.of<SettingsNotifier>(context, listen: false)
              .preferredLanguages;
      for (final preferredLanguage in preferredLanguages) {
        if (languages.contains(preferredLanguage)) {
          lang = preferredLanguage;
          break;
        }
      }
    } else {
      lang = await _showSelectionDialog(
        languages,
        "Wybierz język",
      );
    }
  } else if (languages.isNotEmpty) {
    lang = languages.first;
  } else {
    return (null, null);
  }
  final List<Quality> qualities =
      await _getAvaliableQualitiesForLanguage(lang, directs);
  late Quality quality;
  if (qualities.isNotEmpty) {
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
    try {
      await link.getDirectLink();
      await link.verifyDirectVideoUrl();
      if (link.isVideoValid) {
        validLinks.add(link);
      }
    } catch (e) {
      continue;
    }
  }

  if (validLinks.isEmpty) return null;

  validLinks
      .sort((final a, final b) => a.responseTime.compareTo(b.responseTime));

  return validLinks.first;
}

Future<MediaLink?> getUserSelectedVersion(final List<MediaLink> links) async {
  // links.removeWhere((final link) => link.url.contains(".m3u8") && !supportm3u8);
  final (lang, quality) = await getUserSelectedPreferences(links);
  if (lang == null || quality == null) {
    return null;
  }
  links.removeWhere(
      (final link) => link.language != lang || link.quality != quality);
  return await selectBestLink(links);
}
