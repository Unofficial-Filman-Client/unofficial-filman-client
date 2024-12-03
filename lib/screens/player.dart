import "dart:async";
import "dart:math";
import "dart:io" show Directory;

import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/season.dart";
import "package:unofficial_filman_client/types/video_scrapers.dart";
import "package:unofficial_filman_client/types/watched.dart";
import "package:unofficial_filman_client/utils/select_dialog.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:media_kit/media_kit.dart" hide PlayerState;
import "package:media_kit_video/media_kit_video.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/types/download.dart";
import "package:path_provider/path_provider.dart";
import "package:collection/collection.dart";

class FilmanPlayer extends StatefulWidget {
  final String targetUrl;
  final FilmDetails? filmDetails;
  final FilmDetails? parentDetails;
  final int startFrom;
  final int savedDuration;
  final DownloadedSingle? downloaded;
  final DownloadedSerial? parentDownloaded;

  const FilmanPlayer(
      {super.key,
      required this.targetUrl,
      this.parentDetails,
      this.startFrom = 0,
      this.savedDuration = 0})
      : filmDetails = null,
        downloaded = null,
        parentDownloaded = null;

  const FilmanPlayer.fromDetails(
      {super.key,
      required this.filmDetails,
      this.parentDetails,
      this.startFrom = 0,
      this.savedDuration = 0})
      : targetUrl = "",
        downloaded = null,
        parentDownloaded = null;

  FilmanPlayer.fromDownload(
      {super.key,
      required this.downloaded,
      this.parentDownloaded,
      this.startFrom = 0,
      this.savedDuration = 0})
      : targetUrl = "",
        filmDetails = downloaded?.film,
        parentDetails = parentDownloaded?.serial;

  @override
  State<FilmanPlayer> createState() => _FilmanPlayerState();
}

enum SeekDirection { forward, backward, up, down }

class _FilmanPlayerState extends State<FilmanPlayer> {
  late final Player _player;
  late final VideoController _controller;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<bool> _bufferingSubscription;

  bool _isOverlayVisible = true;
  bool _isBuffering = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _overlayTimer;
  
  int _selectedControlIndex = 1;
  final List<GlobalKey> _controlKeys = List.generate(4, (_) => GlobalKey());

  late FilmDetails _filmDetails;
  FilmDetails? _parentDetails;
  Season? _currentSeason;
  FilmDetails? _nextEpisode;
  DownloadedSingle? _nextDwonloaded;
  String _displayState = "Ładowanie...";

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initMediaKit();
    _initSubscriptions();
    _initPlayer();
    super.initState();
  }

  void _initMediaKit() {
    _player = Player();
    _controller = VideoController(_player);
    _position = Duration(seconds: widget.startFrom);
    _duration = Duration(seconds: widget.savedDuration);
  }

  void _initSubscriptions() {
    _positionSubscription = _controller.player.stream.position.listen((final position) {
      if (widget.startFrom != 0) {
        if (position.inSeconds != 0) {
          setState(() => _position = position);
        }
      } else {
        setState(() => _position = position);
      }
    });

    _durationSubscription = _controller.player.stream.duration.listen((final duration) {
      if (duration.inSeconds > widget.savedDuration) {
        setState(() => _duration = duration);
      }

      if (widget.startFrom > 0) {
        _controller.player.seek(Duration(seconds: widget.startFrom));
      }
      _saveWatched();
      Timer.periodic(const Duration(seconds: 5), (final timer) {
        if (mounted) {
          _saveWatched();
        }
      });
    });

    _playingSubscription = _controller.player.stream.playing.listen((final playing) {
      setState(() {
        _isPlaying = playing;
        _initOverlayTimer();
      });
    });

    _bufferingSubscription = _controller.player.stream.buffering.listen((final buffering) {
      setState(() => _isBuffering = buffering);
    });
  }

  void _initOverlayTimer() {
    _overlayTimer?.cancel();
    if (_isPlaying && !_isBuffering) {
      _overlayTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isPlaying) {
          setState(() {
            _isOverlayVisible = false;
          });
        }
      });
    }
  }

  Future<void> _initPlayer() async {
    if (widget.filmDetails == null) {
      setState(() => _displayState = "Pobieranie informacji o filmie...");
      final details = await Provider.of<FilmanNotifier>(context, listen: false)
          .getFilmDetails(widget.targetUrl);
      setState(() => _filmDetails = details);
    } else {
      setState(() => _filmDetails = widget.filmDetails!);
    }

    if (_filmDetails.isEpisode == true) {
      if (widget.parentDetails != null) {
        setState(() => _parentDetails = widget.parentDetails);
      } else if (_filmDetails.parentUrl != null && mounted) {
        setState(() => _displayState = "Pobieranie informacji o serialu...");
        final parent = await Provider.of<FilmanNotifier>(context, listen: false)
            .getFilmDetails(_filmDetails.parentUrl ?? "");
        setState(() => _parentDetails = parent);
      }

      setState(() {
        _currentSeason = _parentDetails!.seasons!.firstWhere((final element) =>
            element.episodes.any((final element) =>
                element.episodeName == _filmDetails.seasonEpisodeTag));
      });
    }

    if (_filmDetails.isEpisode == true) {
      _loadNextEpisode();
    }

    if (widget.downloaded == null) {
      if (_filmDetails.links != null && mounted) {
        setState(() => _displayState = "Ładowanie listy mediów...");
        final link = await getUserSelectedVersion(context, _filmDetails.links!);
        debugPrint("Selected link: $link");
        if (link == null) return _showNoLinksSnackbar();
        setState(() => _displayState = "Wydobywanie adresu video...");
        final direct = await link.getDirectLink();
        setState(() {
          _displayState = "";
        });
        if (direct == null) return _showNoLinksSnackbar();
        _player.open(Media(direct, httpHeaders: {
          "referer": getBaseUrl(link.url),
        }));
      } else {
        return _showNoLinksSnackbar();
      }
    } else {
      _player.open(Media(Directory(
              "${(await getApplicationDocumentsDirectory()).path}/${widget.downloaded?.filename}")
          .path));
    }
  }

  void _saveWatched() {
    if (_duration.inSeconds == 0) return;
    if (_parentDetails != null && _filmDetails.isEpisode == true) {
      final WatchedSingle lastWatched = WatchedSingle.fromFilmDetails(
          filmDetailsFrom: _filmDetails,
          sec: _position.inSeconds,
          totalSec: _duration.inSeconds,
          parentSeason: _currentSeason);
      Provider.of<WatchedNotifier>(context, listen: false).watchEpisode(
          WatchedSerial.fromFilmDetails(
            filmDetailsFrom: _parentDetails!,
            lastWatchedFromDetails: lastWatched,
          ),
          lastWatched);
    } else if (_filmDetails.isEpisode == false) {
      Provider.of<WatchedNotifier>(context, listen: false).watch(
          WatchedSingle.fromFilmDetails(
              filmDetailsFrom: _filmDetails,
              sec: _position.inSeconds,
              totalSec: _duration.inSeconds));
    }
  }

  void _loadNextEpisode() async {
    final nextDownloaded = widget.parentDownloaded?.episodes.firstWhereOrNull(
        (final e) => e.film.url == _filmDetails.nextEpisodeUrl);
    if (nextDownloaded != null) {
      setState(() {
        _nextDwonloaded = nextDownloaded;
      });
      return;
    }
    if (_filmDetails.nextEpisodeUrl != null) {
      final FilmDetails next =
          await Provider.of<FilmanNotifier>(context, listen: false)
              .getFilmDetails(_filmDetails.nextEpisodeUrl ?? "");
      setState(() {
        _nextEpisode = next;
      });
    }
  }

  void _showNoLinksSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Brak dostępnych linków"),
        dismissDirection: DismissDirection.horizontal,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ));
      Navigator.of(context).pop();
    }
  }

  void _handleDirectionalNavigation(SeekDirection direction) {
    if (!_isOverlayVisible) {
      setState(() => _isOverlayVisible = true);
      _initOverlayTimer();
      return;
    }
    
    switch (direction) {
      case SeekDirection.forward:
        setState(() {
          _selectedControlIndex = (_selectedControlIndex + 1).clamp(0, 3);
        });
        break;
      case SeekDirection.backward:
        setState(() {
          _selectedControlIndex = (_selectedControlIndex - 1).clamp(0, 3);
        });
        break;
      case SeekDirection.up:
        setState(() {
          if (_selectedControlIndex >= 0 && _selectedControlIndex <= 2) {
            _selectedControlIndex = 3;
          }
        });
        break;
      case SeekDirection.down:
        setState(() {
          if (_selectedControlIndex == 3) {
            _selectedControlIndex = 1;
          }
        });
        break;
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  void _handlePlayPause() {
    _saveWatched();
    _player.playOrPause();
    _initOverlayTimer();
  }

  Widget _buildMainStack(final BuildContext context) {
    return Stack(
      children: [
        Video(
          controller: _controller,
          controls: NoVideoControls,
          fit: BoxFit.fitWidth,
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOverlayVisible = !_isOverlayVisible;
            });
            if (_isOverlayVisible) {
              _initOverlayTimer();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: SafeArea(child: _buildOverlay(context)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    return Scaffold(
        body: Focus(
            autofocus: true,
            onKeyEvent: (final FocusNode node, final KeyEvent event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  if (_isOverlayVisible) {
                    switch (_selectedControlIndex) {
                      case 0:
                        _seekRelative(-10);
                        break;
                      case 1:
                        _handlePlayPause();
                        break;
                      case 2:
                        _seekRelative(10);
                        break;
                      case 3:
                        Navigator.of(context).pop();
                        break;
                    }
                  } else {
                    setState(() => _isOverlayVisible = true);
                    _initOverlayTimer();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _handleDirectionalNavigation(SeekDirection.backward);
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _handleDirectionalNavigation(SeekDirection.forward);
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _handleDirectionalNavigation(SeekDirection.up);
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _handleDirectionalNavigation(SeekDirection.down);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: _buildMainStack(context)));
  }

  Widget _buildOverlay(final BuildContext context) {
    return Stack(
      children: [
        _buildLoadingIcon(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isOverlayVisible
              ? Stack(
                  children: [
                    _buildTopBar(),
                    _buildCenterControls(),
                    _buildBottomBar(),
                  ],
                )
              : const SizedBox(),
        )
      ],
    );
  }

  Widget _buildLoadingIcon() {
    if (_isBuffering) {
      return Center(
        child: AnimatedOpacity(
            opacity: _isBuffering ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(_displayState),
              ],
            )),
      );
    }
    return const SizedBox();
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: _controlKeys[3],
                focusNode: FocusNode(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: _selectedControlIndex == 3 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                ),
                onPressed: () {
                  _saveWatched();
                  Navigator.of(context).pop();
                },
              ),
            ),
            Center(
              child: Consumer<SettingsNotifier>(
                builder: (final context, final settings, final child) {
                  try {
                    final displayTitle = getDisplayTitle(_filmDetails.title, settings);
                    return Text(
                      _filmDetails.isEpisode == true
                          ? "$displayTitle - ${_filmDetails.seasonEpisodeTag}"
                          : displayTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    );
                  } catch (err) {
                    return const SizedBox();
                  }
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                transform: Matrix4.translationValues(
                    (_nextEpisode != null || _nextDwonloaded != null) ? 0.0 : 100.0,
                    0.0,
                    0.0),
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity:
                      (_nextEpisode != null || _nextDwonloaded != null) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: OutlinedButton.icon(
                    icon: Text(_nextEpisode?.seasonEpisodeTag ??
                        _nextDwonloaded?.film.seasonEpisodeTag ??
                        "Następny odcinek"),
                    label: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacement(MaterialPageRoute(builder: (final context) {
                        if (_nextEpisode != null) {
                          return FilmanPlayer.fromDetails(filmDetails: _nextEpisode);
                        }
                        if (_nextDwonloaded != null) {
                          return FilmanPlayer.fromDownload(
                            downloaded: _nextDwonloaded,
                            parentDownloaded: widget.parentDownloaded,
                          );
                        }
                        return const Center(child: Text("Wystąpił błąd"));
                      }));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: _controlKeys[0],
            focusNode: FocusNode(),
            iconSize: 48,
            icon: const Icon(Icons.replay_10, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: _selectedControlIndex == 0 ? Colors.white.withOpacity(0.2) : Colors.transparent,
            ),
            onPressed: () => _seekRelative(-10),
          ),
          const SizedBox(width: 32),
          IconButton(
            key: _controlKeys[1],
            focusNode: FocusNode(),
            iconSize: 64,
            style: IconButton.styleFrom(
              backgroundColor: _selectedControlIndex == 1 ? Colors.white.withOpacity(0.2) : Colors.transparent,
            ),
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            onPressed: _handlePlayPause,
          ),
          const SizedBox(width: 32),
          IconButton(
            key: _controlKeys[2],
            focusNode: FocusNode(),
            iconSize: 48,
            style: IconButton.styleFrom(
              backgroundColor: _selectedControlIndex == 2 ? Colors.white.withOpacity(0.2) : Colors.transparent,
            ),
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: () => _seekRelative(10),
          ),
        ],
      ),
    );
  }

  void _seekRelative(final int seconds) {
    final newPosition =
        max(0, min(_position.inSeconds + seconds, _duration.inSeconds));
    _player.seek(Duration(seconds: newPosition));
  }

  Widget _buildBottomBar() {
    final timeText = '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}';
    final durationText = '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}';
    
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  timeText,
                  style: const TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _duration.inSeconds > 0 
                          ? _position.inSeconds / _duration.inSeconds 
                          : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  durationText,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
