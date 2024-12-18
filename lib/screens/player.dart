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

class _FilmanPlayerState extends State<FilmanPlayer> with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<bool> _bufferingSubscription;
  late final AnimationController _overlayAnimationController;

  bool _isOverlayVisible = false;
  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _isSeekingForward = false;
  bool _isSeekingBackward = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _seekSpeed = 10;
  Timer? _seekSpeedTimer;
  Timer? _overlayTimer;
  Timer? _seekTimer;
  static const int maxSeekSpeed = 60;
  bool _isInitialOverlay = true;
  
  int _selectedControlIndex = 1;
  final List<GlobalKey> _controlKeys = List.generate(5, (final _) => GlobalKey());

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

    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _isOverlayVisible = true;
    _initMediaKit();
    _initSubscriptions();
    _initPlayer();
    _initOverlayTimer();
    
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
      
      if (_duration.inSeconds > 0 && 
          position.inSeconds >= _duration.inSeconds - 1 && 
          (_nextEpisode != null || _nextDwonloaded != null)) {
        setState(() {
          _isOverlayVisible = true;
        });
        _overlayAnimationController.forward();
      }
    });

    _durationSubscription = _controller.player.stream.duration.listen((final duration) {
      if (duration.inSeconds > widget.savedDuration) {
        setState(() {
          _duration = duration;
          _isOverlayVisible = true;
        });
        _overlayAnimationController.forward();
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
        if (_isInitialOverlay && playing) {
          _isInitialOverlay = false;
          _initOverlayTimer();
        }
      });
    });

    _bufferingSubscription = _controller.player.stream.buffering.listen((final buffering) {
      setState(() => _isBuffering = buffering);
    });
  }

  void _initOverlayTimer() {
    _overlayTimer?.cancel();
    if (_isPlaying && !_isBuffering && !_isInitialOverlay) {
      _overlayTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isPlaying) {
          setState(() {
            _isOverlayVisible = false;
          });
          _overlayAnimationController.reverse();
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

  void _handleDirectionalNavigation(final SeekDirection direction) {
  if (!_isOverlayVisible) {
    setState(() => _isOverlayVisible = true);
    _overlayAnimationController.forward();
    _initOverlayTimer();
    return;
  }
  
  switch (direction) {
    case SeekDirection.forward:
      setState(() {
        _selectedControlIndex = (_selectedControlIndex + 1).clamp(0, _nextEpisode != null || _nextDwonloaded != null ? 4 : 3);
      });
      break;
    case SeekDirection.backward:
      setState(() {
        _selectedControlIndex = (_selectedControlIndex - 1).clamp(0, _nextEpisode != null || _nextDwonloaded != null ? 4 : 3);
      });
      break;
    case SeekDirection.up:
      setState(() {
        if (_selectedControlIndex >= 0 && _selectedControlIndex <= 2) {
          _selectedControlIndex = 3;
        } else if (_selectedControlIndex == 3 && (_nextEpisode != null || _nextDwonloaded != null)) {
          _selectedControlIndex = 4;
        }
      });
      break;
    case SeekDirection.down:
      setState(() {
        if (_selectedControlIndex == 4) {
          _selectedControlIndex = 3;
        } else if (_selectedControlIndex == 3) {
          _selectedControlIndex = 1;
        }
      });
      break;
  }
}

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _seekTimer?.cancel();
    _seekSpeedTimer?.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    _overlayAnimationController.dispose();
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
      FadeTransition(
        opacity: _overlayAnimationController,
        child: Container(
          color: Colors.black.withOpacity(0.4),
        ),
      ),
      GestureDetector(
        onTap: () {
          setState(() {
            _isOverlayVisible = !_isOverlayVisible;
          });
          if (_isOverlayVisible) {
            _overlayAnimationController.forward();
            _initOverlayTimer();
          } else {
            _overlayAnimationController.reverse();
          }
        },
        child: Container(
          color: Colors.transparent,
          child: SafeArea(
            child: _buildOverlay(context),
          ),
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
                      _handleSeekBackwardStart();
                      break;
                    case 1:
                      _handlePlayPause();
                      break;
                    case 2:
                      _handleSeekForwardStart();
                      break;
                    case 3:
                      Navigator.of(context).pop();
                      break;
                    case 4:
                      _saveWatched();
                      if (_nextDwonloaded != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (final context) => FilmanPlayer.fromDownload(
                              downloaded: _nextDwonloaded,
                              parentDownloaded: widget.parentDownloaded,
                            ),
                          ),
                        );
                      } else if (_nextEpisode != null) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (final context) => FilmanPlayer.fromDetails(
                              filmDetails: _nextEpisode,
                              parentDetails: _parentDetails,
                            ),
                          ),
                        );
                      }
                      break;
                  }
                } else {
                  setState(() => _isOverlayVisible = true);
                  _overlayAnimationController.forward();
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
            } else if (event is KeyUpEvent) {
              if (_isSeekingForward || _isSeekingBackward) {
                _handleSeekStop();
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
        FadeTransition(
          opacity: _overlayAnimationController,
          child: Stack(
            children: [
              _buildTopBar(),
              _buildCenterControls(),
              _buildBottomBar(),
            ],
          ),
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

void _handleSeekForwardStart() {
    if (_isSeekingForward) return;
    
    setState(() {
      _isSeekingForward = true;
      _seekSpeed = 10;
    });
    
    _seekRelative(_seekSpeed);

    _seekTimer = Timer(const Duration(milliseconds: 500), () {
      _startContinuousSeeking(true);
    });
  }

  void _handleSeekBackwardStart() {
    if (_isSeekingBackward) return;
    
    setState(() {
      _isSeekingBackward = true;
      _seekSpeed = 10;
    });
    
    _seekRelative(-_seekSpeed);
    
    _seekTimer = Timer(const Duration(milliseconds: 500), () {
      _startContinuousSeeking(false);
    });
  }

  void _startContinuousSeeking(final bool forward) {
    _seekTimer?.cancel();
    _seekSpeedTimer?.cancel();
    
    _seekTimer = Timer.periodic(const Duration(milliseconds: 200), (final timer) {
      _seekRelative(forward ? _seekSpeed : -_seekSpeed);
    });
    
    _seekSpeedTimer = Timer.periodic(const Duration(seconds: 1), (final timer) {
      setState(() {
        _seekSpeed = min(_seekSpeed * 2, maxSeekSpeed);
      });
    });
  }

  void _handleSeekStop() {
    setState(() {
      _isSeekingForward = false;
      _isSeekingBackward = false;
      _seekSpeed = 10;
    });
    
    _seekTimer?.cancel();
    _seekSpeedTimer?.cancel();
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
            child: MouseRegion(
              child: AnimatedScale(
                scale: _selectedControlIndex == 3 ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  key: _controlKeys[3],
                  focusNode: FocusNode(),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: _selectedControlIndex == 3
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                  onPressed: () {
                    _saveWatched();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
          Center(
            child: Consumer<SettingsNotifier>(
              builder: (final context, final settings, final child) {
                try {
                  final displayTitle =
                      getDisplayTitle(_filmDetails.title, settings);
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
          if (_nextEpisode != null || _nextDwonloaded != null)
            Align(
              alignment: Alignment.centerRight,
              child: MouseRegion(
                child: AnimatedScale(
                  scale: _selectedControlIndex == 4 ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton.icon(
                      key: _controlKeys[4],
                      focusNode: FocusNode(),
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      label: Text(
                        _nextDwonloaded != null
                            ? "${_nextDwonloaded!.film.seasonEpisodeTag}"
                            : "${_nextEpisode?.seasonEpisodeTag}",
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: _selectedControlIndex == 4
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // Matching border radius
                        ),
                      ),
                      onPressed: () {
                        _saveWatched();
                        if (_nextDwonloaded != null) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (final context) =>
                                  FilmanPlayer.fromDownload(
                                downloaded: _nextDwonloaded,
                                parentDownloaded: widget.parentDownloaded,
                              ),
                            ),
                          );
                        } else if (_nextEpisode != null) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (final context) => FilmanPlayer.fromDetails(
                                filmDetails: _nextEpisode,
                                parentDetails: _parentDetails,
                              ),
                            ),
                          );
                        }
                      },
                    ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MouseRegion(
                child: AnimatedScale(
                  scale: _selectedControlIndex == 0 ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTapDown: (final _) => _handleSeekBackwardStart(),
                    onTapUp: (final _) => _handleSeekStop(),
                    onTapCancel: _handleSeekStop,
                    child: IconButton(
                      key: _controlKeys[0],
                      focusNode: FocusNode(),
                      iconSize: 40,
                      icon: Icon(
                        Icons.replay_10,
                        color: _isSeekingBackward ? Theme.of(context).primaryColor : Colors.white
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _selectedControlIndex == 0 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      ),
                      onPressed: () => _seekRelative(-10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              MouseRegion(
                child: AnimatedScale(
                  scale: _selectedControlIndex == 1 ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IconButton(
                    key: _controlKeys[1],
                    focusNode: FocusNode(),
                    iconSize: 56,
                    style: IconButton.styleFrom(
                      backgroundColor: _selectedControlIndex == 1 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    ),
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    onPressed: _handlePlayPause,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              MouseRegion(
                child: AnimatedScale(
                  scale: _selectedControlIndex == 2 ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTapDown: (final _) => _handleSeekForwardStart(),
                    onTapUp: (final _) => _handleSeekStop(),
                    onTapCancel: _handleSeekStop,
                    child: IconButton(
                      key: _controlKeys[2],
                      focusNode: FocusNode(),
                      iconSize: 40,
                      style: IconButton.styleFrom(
                        backgroundColor: _selectedControlIndex == 2 ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      ),
                      icon: Icon(
                        Icons.forward_10,
                        color: _isSeekingForward ? Theme.of(context).primaryColor : Colors.white
                      ),
                      onPressed: () => _seekRelative(10),
                    ),
                  ),
                ),
              ),
            ],
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
