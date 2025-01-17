// ignore_for_file: use_build_context_synchronously

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/types/season.dart";
import "package:unofficial_filman_client/types/watched.dart";
import "package:unofficial_filman_client/utils/select_dialog.dart";
import "package:unofficial_filman_client/notifiers/download.dart";

class EpisodesModal extends StatefulWidget {
  final FilmDetails filmDetails;

  const EpisodesModal({super.key, required this.filmDetails});

  @override
  State<EpisodesModal> createState() => _EpisodesModalState();
}

class _EpisodesModalState extends State<EpisodesModal> {
  Map<String, FilmDetails?> episodeDetails = {};
  List<Season> seasons = [];
  int selectedSeasonIndex = 0;
  Set<String> loadingEpisodes = {};

  @override
  void initState() {
    super.initState();
    seasons = widget.filmDetails.getSeasons();
    _initializeEpisodesMap();
    _startLoadingEpisodes();
  }

  @override
  void dispose() {
    episodeDetails.clear();
    super.dispose();
  }

  void _initializeEpisodesMap() {
    for (Episode episode in seasons[selectedSeasonIndex].getEpisodes()) {
      episodeDetails[episode.episodeName] = null;
    }
  }

  Future<void> _loadEpisode(final Episode episode) async {
    if (!mounted) return;
    
    setState(() => loadingEpisodes.add(episode.episodeName));

    try {
      final data = await context.read<FilmanNotifier>().getFilmDetails(episode.episodeUrl);
      if (!mounted) return;
      setState(() {
        episodeDetails[episode.episodeName] = data;
        loadingEpisodes.remove(episode.episodeName);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loadingEpisodes.remove(episode.episodeName));
    }
  }

  Future<void> _startLoadingEpisodes() async {
    final downloadedSerial = context.read<DownloadNotifier>()
        .downloadedSerials
        .firstWhereOrNull((final s) => s.serial.url == widget.filmDetails.url);
    final savedSerial = context.read<WatchedNotifier>()
        .serials
        .firstWhereOrNull((final s) => s.filmDetails.url == widget.filmDetails.url);

    for (Episode episode in seasons[selectedSeasonIndex].getEpisodes()) {
      if (!mounted) return;

      final watched = savedSerial?.episodes
          .firstWhereOrNull((final e) => e.filmDetails.url == episode.episodeUrl)
          ?.filmDetails ?? 
          downloadedSerial?.episodes
          .firstWhereOrNull((final e) => e.film.url == episode.episodeUrl)
          ?.film;

      if (watched != null) {
        if (!mounted) return;
        setState(() => episodeDetails[episode.episodeName] = watched);
      } else {
        await _loadEpisode(episode);
      }
    }
  }

  Widget _buildProgressBar(final WatchedSingle currentEpisode) {
    final watched = Duration(seconds: currentEpisode.watchedInSec);
    final total = Duration(seconds: currentEpisode.totalInSec);

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${watched.inMinutes}:${(watched.inSeconds % 60).toString().padLeft(2, '0')}'),
          const SizedBox(width: 5),
          Expanded(
            child: LinearProgressIndicator(value: currentEpisode.watchedPercentage),
          ),
          const SizedBox(width: 5),
          Text('${total.inMinutes}:${(total.inSeconds % 60).toString().padLeft(2, '0')}'),
        ],
      ),
    );
  }

  Widget _buildDownloadIcon(final BuildContext context, final FilmDetails filmDetails) {
    final downloaded = context.read<DownloadNotifier>()
        .getEpisodeByUrl(widget.filmDetails, filmDetails.url);
    final isDownloading = context.read<DownloadNotifier>()
        .downloading
        .any((final e) => e.film.url == filmDetails.url);

    return IconButton(
      icon: isDownloading 
          ? const CircularProgressIndicator()
          : Icon(downloaded != null ? Icons.save : Icons.download),
      onPressed: () async {
        if (downloaded != null || filmDetails.links!.isEmpty) {
          return;
        }

        final (link, quality) = await getUserSelectedPreferences(context, filmDetails.links!);
        if (link == null || quality == null || !context.mounted) return;

        context.read<DownloadNotifier>().addFilmToDownload(
          filmDetails,
          link,
          quality,
          context.read<SettingsNotifier>(),
          widget.filmDetails,
        );
      },
    );
  }

  void _onSeasonSelected(final int index) {
    if (selectedSeasonIndex == index) return;
    
    setState(() {
      selectedSeasonIndex = index;
      episodeDetails.clear();
    });
    _initializeEpisodesMap();
    _startLoadingEpisodes();
  }

  Widget _buildSeasonSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        itemBuilder: (final context, final index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FocusableActionDetector(
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (final _) {
                    _onSeasonSelected(index);
                    return null;
                  },
                ),
              },
              child: Builder(
                builder: (final context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return AnimatedScale(
                    scale: hasFocus ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: ChoiceChip(
                      label: Text(seasons[index].seasonTitle),
                      selected: selectedSeasonIndex == index,
                      onSelected: (final selected) {
                        if (selected) _onSeasonSelected(index);
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodesList() {
    return Consumer<WatchedNotifier>(
      builder: (final context, final watchedNotifier, final _) {
        final currentSerial = watchedNotifier.serials
            .firstWhereOrNull((final s) => s.filmDetails.url == widget.filmDetails.url);
        final downloadedSerial = context.watch<DownloadNotifier>()
            .downloadedSerials
            .firstWhereOrNull((final s) => s.serial.url == widget.filmDetails.url);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: seasons[selectedSeasonIndex].getEpisodes().length,
          itemBuilder: (final context, final index) {
            final episode = seasons[selectedSeasonIndex].getEpisodes()[index];
            final currentEpisode = currentSerial?.episodes
                .firstWhereOrNull((final e) => e.filmDetails.url == episode.episodeUrl && e.watchedInSec > 0);
            final downloadedEpisode = downloadedSerial?.episodes
                .firstWhereOrNull((final e) => e.film.url == episode.episodeUrl);
            
            final isLoading = loadingEpisodes.contains(episode.episodeName);
            final details = episodeDetails[episode.episodeName];

            return ListTile(
              autofocus: selectedSeasonIndex == 0 && episode.getEpisodeNumber() == 1,
              title: Row(
                children: [
                  Text(
                    episode.getEpisodeNumber().toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 50,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(episode.getEpisodeTitle()),
                        const SizedBox(height: 4.0),
                        if (isLoading)
                          const LinearProgressIndicator()
                        else if (details != null)
                          details.desc.isNotEmpty && details.desc != widget.filmDetails.desc
                              ? Text(
                                  details.desc,
                                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                                )
                              : const Text(
                                  "Brak opisu odcinka",
                                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                                ),
                        if (currentEpisode != null)
                          _buildProgressBar(currentEpisode),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: details != null
                        ? _buildDownloadIcon(context, details)
                        : const SizedBox(),
                  ),
                ],
              ),
              onTap: () async {
                if (details == null && !isLoading) {
                  await _loadEpisode(episode);
                }
                
                if (!mounted) return;
                final loadedDetails = episodeDetails[episode.episodeName];
                if (loadedDetails == null) return;

                Navigator.of(context).push(MaterialPageRoute(
                  builder: (final context) {
                    if (downloadedEpisode != null) {
                      return FilmanPlayer.fromDownload(
                        downloaded: downloadedEpisode,
                        parentDownloaded: downloadedSerial,
                      );
                    }
                    if (currentEpisode != null) {
                      return FilmanPlayer.fromDetails(
                        filmDetails: loadedDetails,
                        parentDetails: widget.filmDetails,
                        startFrom: currentEpisode.watchedInSec,
                        savedDuration: currentEpisode.totalInSec,
                      );
                    }
                    return FilmanPlayer.fromDetails(
                      filmDetails: loadedDetails,
                      parentDetails: widget.filmDetails,
                    );
                  },
                ));
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Column(
      children: [
        _buildSeasonSelector(),
        Expanded(
          child: SingleChildScrollView(
            child: _buildEpisodesList(),
          ),
        ),
      ],
    );
  }
}