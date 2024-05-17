import 'dart:async';

import 'package:filman_flutter/notifiers/filman.dart';
import 'package:filman_flutter/types/film_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import 'package:system_screen_brightness/system_screen_brightness.dart';

class FilmanPlayer extends StatefulWidget {
  final String targetUrl;
  final FilmDetails? filmDetails;

  FilmanPlayer({super.key, required this.targetUrl}) : filmDetails = null;
  FilmanPlayer.fromDetails({super.key, required this.filmDetails})
      : targetUrl = '';

  @override
  _FilmanPlayerState createState() => _FilmanPlayerState();
}

class _FilmanPlayerState extends State<FilmanPlayer> {
  late final Player _player;
  late final VideoController _controller;
  late final SystemScreenBrightness _brightnessPlugin;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration?> _durationSubscription;
  late final StreamSubscription<bool> _playingSubscription;
  late final StreamSubscription<bool> _bufferingSubscription;

  bool _isOverlayVisible = true;
  bool _isBuffering = true;
  bool _isPlaying = false;
  bool _hasBrightnessPermission = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  FilmDetails? _filmDetails;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _brightnessPlugin = SystemScreenBrightness();

    _initializeSubscriptions();
    _checkBrightnessPermission();
    _initializePlayer();
  }

  void _initializeSubscriptions() {
    _positionSubscription =
        _controller.player.stream.position.listen((position) {
      setState(() => _position = position);
    });

    _durationSubscription =
        _controller.player.stream.duration.listen((duration) {
      setState(() => _duration = duration);
    });

    _playingSubscription = _controller.player.stream.playing.listen((playing) {
      setState(() {
        _isPlaying = playing;
        if (playing) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
        }
      });
    });

    _bufferingSubscription =
        _controller.player.stream.buffering.listen((buffering) {
      setState(() => _isBuffering = buffering);
    });
  }

  Future<void> _initializePlayer() async {
    if (widget.filmDetails == null) {
      final details = await Provider.of<FilmanNotifier>(context, listen: false)
          .getFilmDetails(widget.targetUrl);
      setState(() => _filmDetails = details);
    } else {
      setState(() => _filmDetails = widget.filmDetails);
    }

    final directs = await _filmDetails?.getDirect() ?? [];
    if (directs.length > 1) {
      _showLanguageSelectionDialog(directs);
    } else if (directs.isNotEmpty) {
      _player.open(Media(directs.first.link));
    } else {
      _showNoLinksSnackbar();
    }
  }

  void _showLanguageSelectionDialog(List<DirectLink> directs) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Wybierz język'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: directs
                .map((link) => ListTile(
                      title: Text('${link.qualityVersion} ${link.language}'),
                      onTap: () {
                        _player.open(Media(link.link));
                        Navigator.of(context).pop();
                      },
                    ))
                .toList(),
          ),
        ),
      );
    }
  }

  void _showNoLinksSnackbar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Brak dostępnych linków'),
        dismissDirection: DismissDirection.horizontal,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ));
    }
  }

  Future<void> _checkBrightnessPermission() async {
    final hasPermission = await _brightnessPlugin.checkSystemWritePermission;
    setState(() => _hasBrightnessPermission = hasPermission);
  }

  void _requestPermissions() async {
    await _brightnessPlugin.openAndroidPermissionsMenu();
    setState(() {});
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Video(controller: _controller, controls: NoVideoControls),
          ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isOverlayVisible = !_isOverlayVisible),
      child: AnimatedOpacity(
        opacity: _isOverlayVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            _buildBrightnessControl(context),
            _buildTopBar(),
            _buildCenterPlayPauseButton(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessControl(BuildContext context) {
    return Positioned(
      left: 10,
      top: -10,
      height: MediaQuery.of(context).size.height,
      child: FutureBuilder<double>(
        future: _brightnessPlugin.currentBrightness,
        builder: (context, snapshot) {
          if (!_hasBrightnessPermission) {
            return Center(
              child: IconButton(
                onPressed: () {
                  _checkBrightnessPermission();
                  _requestPermissions();
                },
                icon: const Icon(Icons.no_cell),
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: -1,
                child: Slider(
                  value: snapshot.data ?? 0,
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    _brightnessPlugin
                        .setSystemScreenBrightness((value * 255).toInt());
                  },
                ),
              ),
              Icon(_getBrightnessIcon(snapshot.data ?? 0)),
            ],
          );
        },
      ),
    );
  }

  IconData _getBrightnessIcon(double brightness) {
    if (brightness >= 0.875) return Icons.brightness_7;
    if (brightness >= 0.75) return Icons.brightness_6;
    if (brightness >= 0.625) return Icons.brightness_5;
    if (brightness >= 0.5) return Icons.brightness_4;
    if (brightness >= 0.375) return Icons.brightness_1;
    if (brightness >= 0.25) return Icons.brightness_2;
    if (brightness >= 0.125) return Icons.brightness_3;
    return Icons.brightness_3;
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: 48,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _filmDetails?.title ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayPauseButton() {
    return Center(
      child: _isBuffering
          ? const CircularProgressIndicator()
          : IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 48,
              onPressed: () => _player.playOrPause(),
            ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56),
        width: double.infinity,
        height: 24,
        margin: const EdgeInsets.only(bottom: 32),
        child: Row(
          children: [
            Text(
              '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
            Expanded(
              child: Slider(
                value: _position.inSeconds.toDouble(),
                onChanged: (value) {
                  _controller.player.seek(Duration(seconds: value.toInt()));
                },
                min: 0,
                max: _duration.inSeconds.toDouble(),
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Colors.white,
              ),
            ),
            _duration == Duration.zero
                ? const SizedBox()
                : Text(
                    '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }
}
