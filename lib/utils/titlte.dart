import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class DisplayTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  const DisplayTitle(
      {super.key,
      required this.title,
      this.style,
      this.maxLines,
      this.overflow,
      this.textAlign});

  @override
  Widget build(final BuildContext context) {
    return Consumer<SettingsNotifier>(
      builder: (final context, final settings, final child) {
        return Text(
          getDisplayTitle(title, settings),
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}

String getDisplayTitle(final String title, final SettingsNotifier settings) {
  return title.contains("/")
      ? settings.titleDisplayType == TitleDisplayType.first
          ? title.split("/").first.trim()
          : settings.titleDisplayType == TitleDisplayType.second
              ? title.split("/")[1].trim()
              : title.trim()
      : title.trim();
}
