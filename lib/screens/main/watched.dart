// ignore_for_file: deprecated_member_use

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/watched.dart";

class WatchedPage extends StatefulWidget {
  final Function(bool) onHoverStateChanged;
  
  const WatchedPage({super.key, required this.onHoverStateChanged});
  
  @override
  State<WatchedPage> createState() => _WatchedPageState();
}

class _WatchedPageState extends State<WatchedPage> {
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

  void _showFilmMenu(final BuildContext context, final WatchedSingle film) {
    showDialog(
      context: context,
      builder: (final context) => SimpleDialog(
        title: const Center(child: Text("Opcje dla filmu")),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final context) => FilmanPlayer.fromDetails(
                    filmDetails: film.filmDetails,
                    startFrom: film.watchedInSec,
                    savedDuration: film.totalInSec,
                  ),
                ),
              ).then((final _) => setState(() {}));
            },
            child: const Center(child: Text("Kontynuuj")),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (final context) => film.filmDetails.parentUrl != null
                    ? FilmScreen(
                        url: film.filmDetails.parentUrl!,
                        image: film.filmDetails.imageUrl,
                        title: film.filmDetails.title,
                      )
                    : FilmScreen.fromDetails(details: film.filmDetails),
                ),
              ).then((final _) => setState(() {}));
            },
            child: const Center(child: Text("Informacje")),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmationDialog(context, film);
            },
            child: const Center(child: Text("Usuń")),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(final BuildContext context, final WatchedSingle film) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Potwierdzenie usunięcia"),
        content: Text("Czy na pewno chcesz usunąć \"${film.filmDetails.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Anuluj"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                Provider.of<WatchedNotifier>(context, listen: false).remove(film);
              });
            },
            child: const Text("Usuń"),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchedFilmCard(final BuildContext context, final WatchedSingle film, final int index, {final bool isInFirstRow = false}) {
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
            _showFilmMenu(context, film);
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
          onTap: () => _showFilmMenu(context, film),
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
                      film.filmDetails.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                LinearProgressIndicator(value: film.watchedPercentage),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        film.filmDetails.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8.0),
                      if (film.filmDetails.isEpisode) ...[
                        if (film.filmDetails.seasonEpisodeTag != null)
                          Text(
                            (film.filmDetails.seasonEpisodeTag!.split(" ")..removeAt(0)).join(" "),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.center,
                          ),
                        Text(
                          'S${film.parentSeason?.seasonTitle.replaceAll('Sezon ', '')}:O${1 + (film.parentSeason?.episodes.indexWhere((final e) => e.episodeUrl == film.filmDetails.url) ?? 0)} z ${film.parentSeason?.episodes.length}',
                          style: const TextStyle(fontSize: 16.0),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.center,
                        ),
                      ] else
                        Text(
                          "Pozostało: ${film.totalInSec ~/ 60} min",
                          textAlign: TextAlign.center,
                        ),
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
    return Consumer<WatchedNotifier>(
      builder: (final context, final value, final _) {
        final combined = [...value.films, ...value.serials.map((final e) => e.lastWatched)]
          ..sort((final a, final b) => b.watchedAt.compareTo(a.watchedAt));

        if (combined.isEmpty) {
          return Focus(
            focusNode: _emptyStateFocusNode,
            onFocusChange: widget.onHoverStateChanged,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 50, color: Colors.grey),
                  Text(
                    "Brak filmów w historii oglądania",
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
          itemCount: combined.length,
          itemBuilder: (final context, final index) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 200,
              child: _buildWatchedFilmCard(
                context,
                combined[index],
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