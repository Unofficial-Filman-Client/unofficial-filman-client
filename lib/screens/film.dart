import "package:collection/collection.dart";
import "package:unofficial_filman_client/notifiers/download.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/notifiers/watched.dart";
import "package:unofficial_filman_client/screens/player.dart";
import "package:unofficial_filman_client/types/film_details.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";
import "package:unofficial_filman_client/utils/select_dialog.dart";
import "package:unofficial_filman_client/utils/title.dart";
import "package:unofficial_filman_client/widgets/episodes.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";
import "package:share_plus/share_plus.dart";
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
    return Transform(
      transform: Matrix4.translationValues(-16, -12, 0),
      child: LinearProgressIndicator(
        value: watched.watchedPercentage,
      ),
    );
  }

  void _showBottomSheet(final FilmDetails filmDetails) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (final context) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: EpisodesModal(
            filmDetails: filmDetails,
          ),
        );
      },
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryTags(film.categories),
                    const SizedBox(height: 16),
                    _buildTitleAndImage(context, film),
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
                                    final direct = await getUserSelectedVersion(
                                        snapshot.data?.links ?? [],
                                        context,
                                        false);
                                    if (direct == null) {
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
                                              direct!.language,
                                              direct.qualityVersion,
                                              Provider.of<SettingsNotifier>(
                                                  context,
                                                  listen: false))
                                          .then((final _) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text("Dodano do kolejki"),
                                            dismissDirection:
                                                DismissDirection.horizontal,
                                            behavior: SnackBarBehavior.floating,
                                            showCloseIcon: true,
                                          ));
                                        }
                                      }).catchError((final err) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text("Błąd: $err"),
                                            dismissDirection:
                                                DismissDirection.horizontal,
                                            behavior: SnackBarBehavior.floating,
                                            showCloseIcon: true,
                                          ));
                                        }
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.download))
                              : const SizedBox());
                },
              )
            ],
          ),
          _buildProgressBar(Provider.of<WatchedNotifier>(context))
        ],
      )),
      floatingActionButton: FutureBuilder<FilmDetails>(
        future: lazyFilm,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return FloatingActionButton(
              onPressed: () {},
              child: const CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.error),
            );
          } else if (snapshot.hasData) {
            final film = snapshot.data!;
            final watched = Provider.of<WatchedNotifier>(context, listen: false)
                .films
                .firstWhereOrNull(
                    (final element) => element.filmDetails.url == film.url);
            return FloatingActionButton(
              child: Icon(film.isSerial ? Icons.list : Icons.play_arrow),
              onPressed: () async {
                if (film.isSerial) {
                  if (film.seasons?.isNotEmpty == true) {
                    _showBottomSheet(film);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Brak dostępnych sezonów"),
                      dismissDirection: DismissDirection.horizontal,
                      behavior: SnackBarBehavior.floating,
                      showCloseIcon: true,
                    ));
                  }
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (final context) => watched != null
                        ? FilmanPlayer.fromDetails(
                            filmDetails: film,
                            startFrom: watched.watchedInSec,
                            savedDuration: watched.totalInSec,
                          )
                        : FilmanPlayer.fromDetails(filmDetails: film),
                  ));
                }
              },
            );
          } else {
            return const SizedBox();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
        fontSize: 16,
      ),
    );
  }

  Widget _buildTitleAndImage(
      final BuildContext context, final FilmDetails film) {
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
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(film.releaseDate),
          avatar: const Icon(Icons.calendar_today),
        ),
        Chip(
          label: Text(film.viewCount),
          avatar: const Icon(Icons.visibility),
        ),
        Chip(
          label: Text(film.country),
          avatar: const Icon(Icons.flag),
        ),
      ],
    );
  }

  Widget _buildDescription(final String? description) {
    return Text(
      description ?? "Brak opisu",
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    );
  }
}
