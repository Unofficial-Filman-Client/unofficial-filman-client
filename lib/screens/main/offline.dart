// ignore_for_file: deprecated_member_use

import "package:background_downloader/background_downloader.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";

class OfflinePage extends StatefulWidget {
  final Function(bool) onHoverStateChanged;
  
  const OfflinePage({
    super.key, 
    required this.onHoverStateChanged
  });
  
  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final List<FocusNode> _focusNodes = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _emptyStateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 100; i++) {
      _focusNodes.add(FocusNode());
    }
  }

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
      builder: (final context) {
        return SimpleDialog(
          title: const Center(child: Text("Opcje")),
          children: [
            if (item is DownloadedSingle)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (final context) => FilmanPlayer.fromDownload(downloaded: item),
                  ));
                },
                child: const Center(child: Text("Odtwórz")),
              ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                if (item is DownloadedSingle) {
                  _showDeleteDialog(context, item);
                } else if (item is Downloading) {
                  Provider.of<DownloadNotifier>(context, listen: false)
                      .cancelDownload(item);
                }
              },
              child: const Center(
                child: Text("Usuń"),
              ),
            ),
          ],
        );
      },
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

  Widget _buildDownloadedCard(
  final BuildContext context, 
  final DownloadedSingle download, 
  final int index,
  {final bool isFirstItem = false}
) {
  return Focus(
    focusNode: _focusNodes[index],
    onKey: (final node, final event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (index + 3 < _focusNodes.length) {
            _focusNodes[index + 3].requestFocus();
            _scrollToVisible(index + 3);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (index < 3) {
            widget.onHoverStateChanged(false);
            return KeyEventResult.handled;
          } else if (index - 3 >= 0) {
            _focusNodes[index - 3].requestFocus();
            _scrollToVisible(index - 3);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (index % 3 != 0) {
            _focusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (index % 3 != 2 && index + 1 < _focusNodes.length) {
            _focusNodes[index + 1].requestFocus();
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.select ||
                   event.logicalKey == LogicalKeyboardKey.enter) {
          _showItemMenu(context, download);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    onFocusChange: (final hasFocus) {
      setState(() {});
      if (isFirstItem) {
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
      child: Card(
        child: InkWell(
          onTap: () => _showItemMenu(context, download),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FastCachedImage(
                  url: download.film.imageUrl,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      download.film.title,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildDownloadingCard(
  final BuildContext context, 
  final Downloading download, 
  final int index,
  {final bool isFirstItem = false}
) {
  return Focus(
    focusNode: _focusNodes[index],
    onKey: (final node, final event) {
      if (event is RawKeyDownEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (index + 3 < _focusNodes.length) {
            _focusNodes[index + 3].requestFocus();
            _scrollToVisible(index + 3);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (index - 3 >= 0) {
            _focusNodes[index - 3].requestFocus();
            _scrollToVisible(index - 3);
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (index % 3 != 0) {
            _focusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (index % 3 != 2 && index + 1 < _focusNodes.length) {
            _focusNodes[index + 1].requestFocus();
            return KeyEventResult.handled;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.select ||
                   event.logicalKey == LogicalKeyboardKey.enter) {
          _showItemMenu(context, download);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    },
    onFocusChange: (final hasFocus) {
      setState(() {});
      if (isFirstItem) {
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
      child: Card(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                    child: FastCachedImage(
                      url: download.film.imageUrl,
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
                        if (download.isSerial)
                          Text(
                            download.film.seasonEpisodeTag ?? "",
                            style: const TextStyle(fontSize: 16.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        StreamBuilder<TaskStatusUpdate>(
                          stream: download.status.stream,
                          builder: (final context, final snapshot) {
                            if (!snapshot.hasData) {
                              return const Text("Brak danych");
                            }
                            final status = snapshot.data!.status;
                            if (status == TaskStatus.failed) {
                              return Text(
                                "Wystąpił błąd (${snapshot.data?.exception})",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            } else if (status == TaskStatus.running) {
                              return StreamBuilder<TaskProgressUpdate>(
                                stream: download.progress.stream,
                                builder: (final context, final progressSnapshot) => Row(
                                  children: [
                                    Text(
                                        "${((progressSnapshot.data?.progress ?? 0) * 100).toStringAsFixed(0)}%"),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                          value: progressSnapshot.data?.progress ?? 0.0),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const Text("Brak danych");
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showDeleteDialog(final BuildContext context, final DownloadedSingle download) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Usuwanie z historii"),
        content: Consumer<SettingsNotifier>(
          builder: (final context, final settings, final child) => Text(
            "Czy na pewno chcesz usunąć \"${getDisplayTitle(download.film.title, settings)}\" z pobranych?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Usuń"),
          ),
        ],
      ),
    );
  }

  @override
Widget build(final BuildContext context) {
  return Consumer<DownloadNotifier>(
    builder: (final context, final value, final child) {
      final totalItems = value.downloaded.length +
          value.downloadedSerials.length +
          value.downloading.length;

      if (totalItems == 0) {
  return Focus(
    focusNode: _emptyStateFocusNode,
    onFocusChange: (final hasFocus) {
      widget.onHoverStateChanged(hasFocus);
    },
    child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_rounded, size: 50, color: Colors.grey),
                Text(
                  "Brak pobranych filmów",
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.grey),
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
            mainAxisExtent: 200,
          ),
          padding: const EdgeInsets.all(10),
          itemCount: totalItems,
          itemBuilder: (final context, final index) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: 200,
        child: Builder(
          builder: (final context) {
            final isFirstItem = index == 0;
            if (index < value.downloaded.length) {
              return _buildDownloadedCard(
                context, 
                value.downloaded[index], 
                index,
                isFirstItem: isFirstItem,
              );
            } else if (index < value.downloaded.length + value.downloadedSerials.length) {
              return _buildDownloadedCard(
                context,
                value.downloadedSerials[index - value.downloaded.length].episodes.first,
                index,
                isFirstItem: isFirstItem,
              );
            } else {
              return _buildDownloadingCard(
                context,
                value.downloading[index - value.downloaded.length - value.downloadedSerials.length],
                index,
                isFirstItem: isFirstItem,
              );
            }
          },
        ),
      ),
    );
  },
);
},
);
}
}
