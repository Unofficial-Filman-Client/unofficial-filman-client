// ignore_for_file: deprecated_member_use

import "package:background_downloader/background_downloader.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:unofficial_filman_client/utils/navigation_service.dart";
import "package:unofficial_filman_client/utils/title.dart";

class OfflinePage extends StatefulWidget {
  final Function(bool) onHoverStateChanged;
  
  const OfflinePage({super.key, required this.onHoverStateChanged});
  
  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final List<FocusNode> _focusNodes = List.generate(100, (final _) => FocusNode());
  final ScrollController _scrollController = ScrollController();
  final FocusNode _emptyStateFocusNode = FocusNode();

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    _scrollController.dispose();
    _emptyStateFocusNode.dispose();
    super.dispose();
  }

  void _showItemMenu(final BuildContext context, final dynamic item) {
    showDialog(
      context: context,
      builder: (final context) => SimpleDialog(
        title: const Center(child: Text("Opcje dla filmu")),
        children: [
          if (item is DownloadedSingle) ...[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (final context) => FilmanPlayer.fromDownload(downloaded: item),
                  ),
                ).then((final _) => setState(() {}));
              },
              child: const Center(child: Text("Odtwórz")),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context, item);
              },
              child: const Center(child: Text("Usuń")),
            ),
          ] else if (item is Downloading)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Provider.of<DownloadNotifier>(context, listen: false).cancelDownload(item);
              },
              child: const Center(child: Text("Anuluj pobieranie")),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(final BuildContext context, final DownloadedSingle download) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Potwierdzenie usunięcia"),
        content: Consumer<SettingsNotifier>(
          builder: (final context, final settings, final child) => 
            Text("Czy na pewno chcesz usunąć \"${getDisplayTitle(download.film.title, settings)}\" z pobranych?"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<DownloadNotifier>(context, listen: false).removeDownloaded(download);
            },
            child: const Text("Usuń"),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineCard(final BuildContext context, final dynamic item, final int index, {final bool isInFirstRow = false}) {
    return Focus(
      focusNode: _focusNodes[index],
      onKey: (final node, final event) {
        if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowDown:
            if (index + 3 < _focusNodes.length) {
              _focusNodes[index + 3].requestFocus();
              _scrollToVisible(index + 3);
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.arrowUp:
            if (index < 3) {
              widget.onHoverStateChanged(false);
              return KeyEventResult.handled;
            } else if (index - 3 >= 0) {
              _focusNodes[index - 3].requestFocus();
              _scrollToVisible(index - 3);
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.arrowLeft:
            if (index - 1 >= 0 && index % 3 != 0) {
              _focusNodes[index - 1].requestFocus();
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.arrowRight:
            if (index + 1 < _focusNodes.length && (index + 1) % 3 != 0) {
              _focusNodes[index + 1].requestFocus();
              return KeyEventResult.handled;
            }
            break;
          case LogicalKeyboardKey.select:
          case LogicalKeyboardKey.enter:
            _showItemMenu(context, item);
            return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      onFocusChange: (final hasFocus) {
        setState(() {});
        if (isInFirstRow) {
          widget.onHoverStateChanged(hasFocus);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: _focusNodes[index].hasFocus ? Colors.blue : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: GestureDetector(
          onTap: () => _showItemMenu(context, item),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: Image.network(
                      item is DownloadedSingle ? item.film.imageUrl : item.film.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (item is Downloading)
                  StreamBuilder<TaskProgressUpdate>(
                    stream: item.progress.stream,
                    builder: (final context, final snapshot) => LinearProgressIndicator(
                      value: snapshot.data?.progress ?? 0.0,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        item is DownloadedSingle ? item.film.title : item.film.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4.0),
                      if (item is Downloading) ...[
                        StreamBuilder<TaskStatusUpdate>(
                          stream: item.status.stream,
                          builder: (final context, final snapshot) {
                            if (!snapshot.hasData) return const Text("Rozpoczynanie...");
                            
                            final status = snapshot.data!.status;
                            if (status == TaskStatus.failed) {
                              return Text(
                                "Błąd: ${snapshot.data?.exception}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            } else if (status == TaskStatus.running) {
                              return StreamBuilder<TaskProgressUpdate>(
                                stream: item.progress.stream,
                                builder: (final context, final progressSnapshot) => 
                                  Text("${((progressSnapshot.data?.progress ?? 0) * 100).toStringAsFixed(0)}%"),
                              );
                            }
                            return const Text("Oczekiwanie...");
                          },
                        ),
                      ] else if (item.film.isEpisode) ...[
                        if (item.film.seasonEpisodeTag != null)
                          Text(
                            item.film.seasonEpisodeTag!,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToVisible(final int index) {
    final double position = (index ~/ 3) * 200.0;
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Consumer<DownloadNotifier>(
      builder: (final context, final value, final child) {
        final allItems = [
          ...value.downloading,
          ...value.downloaded,
          ...value.downloadedSerials.expand((final serial) => serial.episodes),
        ];

        if (allItems.isEmpty) {
          return Focus(
            focusNode: _emptyStateFocusNode,
            onFocusChange: widget.onHoverStateChanged,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 50, color: Colors.grey),
                  Text(
                    "Brak pobranych filmów",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 10,
            mainAxisExtent: 200.0,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: allItems.length,
          itemBuilder: (final context, final index) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 200,
              child: _buildOfflineCard(
                context,
                allItems[index],
                index,
                isInFirstRow: index < 3,
              ),
            ),
          ),
        );
      },
    );
  }
}