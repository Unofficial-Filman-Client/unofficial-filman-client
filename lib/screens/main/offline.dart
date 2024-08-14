import "package:background_downloader/background_downloader.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:unofficial_filman_client/utils/titlte.dart";
import "package:unofficial_filman_client/widgets/episodes.dart";

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

Widget _buildDownloadedCard(final DownloadedSingle download) {
  return Card(
    child: InkWell(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: Image.network(
                download.film.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DisplayTitle(
                    title: download.film.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildDownloadedSerialCard(
    final BuildContext context, final DownloadedSerial download) {
  return Card(
    child: InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          builder: (final context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: EpisodesModal(
                filmDetails: download.serial,
              ),
            );
          },
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        child: Image.network(
          download.serial.imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

Widget _buildDownloadingCard(final BuildContext context,
    void setState(void Function() fn), final Downloading download) {
  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Image.network(
              download.film.imageUrl,
              fit: BoxFit.cover,
              height: 256,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DisplayTitle(
                  title: download.film.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                StreamBuilder<TaskStatusUpdate>(
                    stream: download.status.stream,
                    builder: (final context, final snapshot) {
                      if (snapshot.hasData) {
                        final status = snapshot.data!.status;
                        switch (status) {
                          case TaskStatus.failed:
                            return Text(
                                "Wystąpił błąd (${snapshot.data?.exception})");
                          case TaskStatus.running:
                            return StreamBuilder<TaskProgressUpdate>(
                                stream: download.progress.stream,
                                builder: (final context, final snapshot) =>
                                    Row(children: [
                                      Text(
                                          "${((snapshot.data?.progress ?? 0) * 100).toStringAsFixed(0)}%"),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: LinearProgressIndicator(
                                              value: snapshot.data?.progress ??
                                                  0.0)),
                                    ]));
                          default:
                            return const Text("Brak danych");
                        }
                      }
                      return const Text("Brak danych");
                    }),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      Provider.of<DownloadNotifier>(context, listen: false)
                          .cancelDownload(download);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _OfflinePageState extends State<OfflinePage> {
  @override
  Widget build(final BuildContext context) {
    return Consumer<DownloadNotifier>(
        builder: (final context, final value, final child) =>
            value.downloading.isEmpty &&
                    value.downloaded.isEmpty &&
                    value.downloadedSerials.isEmpty
                ? Center(
                    child: Text("Brak pobranych filmów",
                        style: Theme.of(context).textTheme.labelLarge),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (MediaQuery.of(context).size.width ~/
                              (MediaQuery.of(context).size.height / 2.5)) +
                          1,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.6,
                    ),
                    padding: const EdgeInsets.all(10),
                    itemCount: value.downloaded.length +
                        value.downloadedSerials.length +
                        value.downloading.length,
                    itemBuilder: (final BuildContext context, final int index) {
                      if (index < value.downloaded.length) {
                        return _buildDownloadedCard(value.downloaded[index]);
                      } else if (index <
                          value.downloaded.length +
                              value.downloadedSerials.length) {
                        return _buildDownloadedSerialCard(
                            context,
                            value.downloadedSerials[
                                index - value.downloaded.length]);
                      } else {
                        return _buildDownloadingCard(
                            context,
                            setState,
                            value.downloading[index -
                                value.downloaded.length -
                                value.downloadedSerials.length]);
                      }
                    },
                  ));
  }
}
