import "package:collection/collection.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:unofficial_filman_client/widgets/episodes.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/widgets/focus_inkwell.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";

class FilmScreen extends StatefulWidget {
  final String url, title, image;
  final FilmDetails? filmDetails;

  const FilmScreen({
    super.key,
    required this.url,
    required this.title,
    required this.image,
    this.filmDetails,
  });

  FilmScreen.fromDetails({
    super.key,
    required final FilmDetails details,
  })  : url = details.url,
        title = details.title,
        image = details.imageUrl,
        filmDetails = details;

  @override
  State<FilmScreen> createState() => _FilmScreenState();
}

class _FilmScreenState extends State<FilmScreen> {
  late Future<FilmDetails> lazyFilm;

  @override
  void initState() {
    super.initState();
    if (widget.filmDetails != null) {
      lazyFilm = Future.value(widget.filmDetails);
    } else {
      lazyFilm = Provider.of<FilmanNotifier>(context, listen: false)
          .getFilmDetails(widget.url);
    }
  }

  Widget _buildProgressBar(final WatchedNotifier watchedNotifier) {
    final watched = watchedNotifier.films.firstWhereOrNull(
        (final element) => element.filmDetails.url == widget.url);
    if (watched == null) return const SizedBox();
    return LinearProgressIndicator(
      value: watched.watchedPercentage,
    );
  }

  void _showEpisodesDialog(final FilmDetails filmDetails) {
    showDialog(
      context: context,
      builder: (final context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: EpisodesModal(
            filmDetails: filmDetails,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      final IconData icon, final String label, final bool hasFocus) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: hasFocus
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFocus
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.outline.withOpacity(0.12),
          width: hasFocus ? 2 : 1,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: hasFocus
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: hasFocus
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: FutureBuilder<FilmDetails>(
        future: lazyFilm,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return ErrorHandling(
                error: snapshot.error!,
                onLogin: (final response) => Navigator.of(context)
                    .pushReplacement(MaterialPageRoute(
                        builder: (final context) => FilmScreen(
                            url: widget.url,
                            title: widget.title,
                            image: widget.image))));
          } else if (snapshot.hasData) {
            final film = snapshot.data!;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: FastCachedImage(
                            url: widget.image,
                            width: MediaQuery.of(context).size.width * 0.3,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DisplayTitle(
                                title: widget.title,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCategoryTags(film.categories),
                              const SizedBox(height: 16),
                              _buildFilmDetailsChips(film),
                              const SizedBox(height: 16),
                              _buildDescription(film.desc),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  FocusInkWell(
                                    onTap: () => Navigator.of(context).pop(),
                                    builder: (final hasFocus) =>
                                        _buildActionButton(
                                      Icons.arrow_back,
                                      "Powrót",
                                      hasFocus,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  FocusInkWell(
                                    onTap: () async {
                                      if (film.isSerial) {
                                        if (film.seasons?.isNotEmpty == true) {
                                          _showEpisodesDialog(film);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content:
                                                Text("Brak dostępnych sezonów"),
                                            behavior: SnackBarBehavior.floating,
                                          ));
                                        }
                                      } else {
                                        final watched =
                                            Provider.of<WatchedNotifier>(
                                          context,
                                          listen: false,
                                        ).films.firstWhereOrNull(
                                                (final element) =>
                                                    element.filmDetails.url ==
                                                    film.url);

                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (final context) =>
                                              watched != null
                                                  ? FilmanPlayer.fromDetails(
                                                      filmDetails: film,
                                                      startFrom:
                                                          watched.watchedInSec,
                                                      savedDuration:
                                                          watched.totalInSec,
                                                    )
                                                  : FilmanPlayer.fromDetails(
                                                      filmDetails: film),
                                        ));
                                      }
                                    },
                                    autofocus: true,
                                    builder: (final hasFocus) =>
                                        _buildActionButton(
                                      film.isSerial
                                          ? Icons.list
                                          : Icons.play_arrow,
                                      film.isSerial ? "Odcinki" : "Odtwórz",
                                      hasFocus,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProgressBar(Provider.of<WatchedNotifier>(context)),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text("Brak danych"));
          }
        },
      ),
    );
  }

  Widget _buildCategoryTags(final List<String>? categories) {
    return Text(
      categories?.isNotEmpty == true
          ? categories!.join(" ").toUpperCase()
          : "Brak kategorii",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        fontSize: 20,
      ),
    );
  }

  Widget _buildFilmDetailsChips(final FilmDetails film) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        Chip(
          label: Text(
            film.releaseDate,
            style: const TextStyle(fontSize: 16),
          ),
          avatar: const Icon(Icons.calendar_today),
        ),
        Chip(
          label: Text(
            film.viewCount,
            style: const TextStyle(fontSize: 16),
          ),
          avatar: const Icon(Icons.visibility),
        ),
        Chip(
          label: Text(
            film.country,
            style: const TextStyle(fontSize: 16),
          ),
          avatar: const Icon(Icons.flag),
        ),
      ],
    );
  }

  Widget _buildDescription(final String? description) {
    return Text(
      description ?? "Brak opisu",
      maxLines: 7,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 18,
        height: 1.5,
      ),
    );
  }
}
