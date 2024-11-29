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
                    _buildCategoryTags(film.categories),
                    const SizedBox(height: 16),
                    _buildTitleAndImage(film),
                    const SizedBox(height: 16),
                    _buildFilmDetailsChips(film),
                    const SizedBox(height: 16),
                    _buildDescription(film.desc),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text("Brak danych"));
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
          child: Stack(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: Navigator.of(context).pop,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  Share.share(
                      "Oglądaj '${widget.title}' za darmo na ${widget.url}");
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                  final Uri uri = Uri.parse(widget.url);
                  if (!await launchUrl(uri,
                      mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("Nie można otworzyć linku w przeglądarce"),
                        dismissDirection: DismissDirection.horizontal,
                        behavior: SnackBarBehavior.floating,
                        showCloseIcon: true,
                      ));
                    }
                  }
                },
              ),
              FutureBuilder<FilmDetails>(
                future: lazyFilm,
                builder: (final context, final snapshot) {
                  final isDownloading = Provider.of<DownloadNotifier>(context)
                      .downloading
                      .any((final element) => element.film.url == widget.url);
                  return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isDownloading
                          ? const IconButton(
                              onPressed: null,
                              icon: Icon(Icons.downloading),
                            )
                          : snapshot.data?.isSerial == false && snapshot.hasData
                              ? IconButton(
                                  onPressed: () async {
                                    final link = await getUserSelectedVersion(
                                        snapshot.data?.links ?? []);
                                    if (link == null) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text("Brak dostępnych linków"),
                                          dismissDirection:
                                              DismissDirection.horizontal,
                                          behavior: SnackBarBehavior.floating,
                                          showCloseIcon: true,
                                        ));
                                        return;
                                      }
                                    }

                                    if (context.mounted) {
                                      Provider.of<DownloadNotifier>(context,
                                              listen: false)
                                          .addFilmToDownload(
                                              snapshot.data!,
                                              link!.language,
                                              link.quality,
                                              Provider.of<SettingsNotifier>(
                                                  context,
                                                  listen: false))
                                          .then((final _) {
                                        if (context.mounted) {
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

  Widget _buildTitleAndImage(final FilmDetails film) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: FastCachedImage(
            url: widget.image,
            width: MediaQuery.of(context).size.width * 0.3,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: DisplayTitle(
            title: widget.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
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
