import "package:background_downloader/background_downloader.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/utils/titlte.dart";

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  @override
  Widget build(final BuildContext context) {
    final download = Provider.of<DownloadNotifier>(context).downloads;
    return download.isEmpty
        ? Center(
            child: Text("Brak pobranych filmów",
                style: Theme.of(context).textTheme.labelLarge),
          )
        : ListView(
            children: [
              for (final download in download)
                ListTile(
                  title: DisplayTitle(title: download.film.title),
                  subtitle: StreamBuilder<TaskProgressUpdate>(
                      stream: download.progress.stream,
                      builder: (final context, final snapshot) {
                        return Text(
                            "${((snapshot.data?.progress ?? 0) * 100).round()}%");
                      }),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {},
                  ),
                  leading: Image.network(
                    download.film.imageUrl,
                    height: 256,
                  ),
                ),
            ],
          );
  }
}
