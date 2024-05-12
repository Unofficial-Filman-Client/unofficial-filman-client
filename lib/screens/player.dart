import 'dart:async';

import 'package:filman_flutter/types/film_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:system_screen_brightness/system_screen_brightness.dart';

class FilmanPlayer extends StatefulWidget {
  final FilmDetails filmDetails;
  final DirectLink selectedLink;

  const FilmanPlayer(
      {super.key, required this.filmDetails, required this.selectedLink});

  @override
  State<FilmanPlayer> createState() => _FilmanPlayerState();
}

class _FilmanPlayerState extends State<FilmanPlayer> {
  late final player = Player();
  late final controller = VideoController(player);
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<bool> _playingSubscription;
  late StreamSubscription<bool> _bufferingSubscription;
  bool _isOverlayVisible = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _buffering = true;
  late final SystemScreenBrightness _systemScreenBrightnessPlugin;
  bool _hasBrightnessPermission = false;

  @override
  void initState() {
    super.initState();

    _systemScreenBrightnessPlugin = SystemScreenBrightness();

    player.open(Media(widget.selectedLink.link));

    _positionSubscription =
        controller.player.stream.position.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _durationSubscription =
        controller.player.stream.duration.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _playingSubscription = controller.player.stream.playing.listen((playing) {
      setState(() {
        _playing = playing;
        if (playing) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
        }
      });
    });

    _bufferingSubscription =
        controller.player.stream.buffering.listen((buffering) {
      setState(() {
        _buffering = buffering;
      });
    });
    checkBrightnessPermission();
  }

  void checkBrightnessPermission() async {
    final bool hasPermission =
        await _systemScreenBrightnessPlugin.checkSystemWritePermission;
    setState(() {
      _hasBrightnessPermission = hasPermission;
    });
  }

  void requestPerms() async {
    await _systemScreenBrightnessPlugin.openAndroidPermissionsMenu();
    setState(() {});
  }

  @override
  void dispose() {
    player.dispose();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Video(controller: controller, controls: NoVideoControls),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _isOverlayVisible = !_isOverlayVisible;
              });
            },
            child: AnimatedOpacity(
                opacity: _isOverlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    Positioned(
                        left: 0,
                        top: -10,
                        height: MediaQuery.of(context).size.height,
                        child: FutureBuilder<double>(
                            future:
                                _systemScreenBrightnessPlugin.currentBrightness,
                            builder: (context, snapshot) {
                              if (!_hasBrightnessPermission) {
                                return IconButton(
                                    onPressed: () => requestPerms(),
                                    icon: const Icon(Icons.no_cell));
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
                                        setState(() {
                                          _systemScreenBrightnessPlugin
                                              .setSystemScreenBrightness(
                                                  (value * 255).toInt());
                                        });
                                      },
                                    ),
                                  ),
                                  Icon(snapshot.data! >= 0.875
                                      ? Icons.brightness_7
                                      : snapshot.data! >= 0.75
                                          ? Icons.brightness_6
                                          : snapshot.data! >= 0.625
                                              ? Icons.brightness_5
                                              : snapshot.data! >= 0.5
                                                  ? Icons.brightness_4
                                                  : snapshot.data! >= 0.375
                                                      ? Icons.brightness_1
                                                      : snapshot.data! >= 0.25
                                                          ? Icons.brightness_2
                                                          : snapshot.data! >=
                                                                  0.125
                                                              ? Icons
                                                                  .brightness_3
                                                              : Icons
                                                                  .brightness_3)
                                ],
                              );
                            })),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        height: 48,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  widget.filmDetails.title,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                        child: _buffering
                            ? const CircularProgressIndicator()
                            : IconButton(
                                icon: Icon(
                                    _playing ? Icons.pause : Icons.play_arrow),
                                iconSize: 48,
                                onPressed: () {
                                  player.playOrPause();
                                },
                              )),
                    Align(
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
                                final Duration newPosition =
                                    Duration(seconds: value.toInt());
                                controller.player.seek(newPosition);
                              },
                              min: 0,
                              max: _duration.inSeconds.toDouble(),
                              activeColor: colorScheme.primary,
                              inactiveColor: Colors.white,
                            )),
                            _duration.inMinutes == 0 && _duration.inSeconds == 0
                                ? const SizedBox()
                                : Text(
                                    '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ],
                        ),
                      ),
                    )
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
