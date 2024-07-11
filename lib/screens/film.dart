import 'package:unofficial_filman_client/notifiers/filman.dart';
import 'package:unofficial_filman_client/screens/player.dart';
import 'package:unofficial_filman_client/types/film_details.dart';
import 'package:unofficial_filman_client/utils/error_handling.dart';
import 'package:unofficial_filman_client/utils/titlte.dart';
import 'package:unofficial_filman_client/widgets/episodes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
    required FilmDetails details,
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

  void _showBottomSheet(FilmDetails filmDetails) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (context) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<FilmDetails>(
        future: lazyFilm,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return buildErrorContent(
                snapshot.error!,
                context,
                (response) => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => FilmScreen(
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
            return const Center(child: Text('Brak danych'));
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
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
                      content: Text('Nie można otworzyć linku w przeglądarce'),
                      dismissDirection: DismissDirection.horizontal,
                      behavior: SnackBarBehavior.floating,
                      showCloseIcon: true,
                    ));
                  }
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder<FilmDetails>(
        future: lazyFilm,
        builder: (context, snapshot) {
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
            return FloatingActionButton(
              child: Icon(film.isSerial ? Icons.list : Icons.play_arrow),
              onPressed: () async {
                if (film.isSerial) {
                  if (film.seasons?.isNotEmpty == true) {
                    _showBottomSheet(film);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Brak dostępnych sezonów'),
                      dismissDirection: DismissDirection.horizontal,
                      behavior: SnackBarBehavior.floating,
                      showCloseIcon: true,
                    ));
                  }
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        FilmanPlayer.fromDetails(filmDetails: film),
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

  Widget _buildCategoryTags(List<String>? categories) {
    return Text(
      categories?.isNotEmpty == true
          ? categories!.join(' ').toUpperCase()
          : "Brak kategorii",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        fontSize: 16,
      ),
    );
  }

  Widget _buildTitleAndImage(BuildContext context, FilmDetails film) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            widget.image,
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

  Widget _buildFilmDetailsChips(FilmDetails film) {
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

  Widget _buildDescription(String? description) {
    return Text(
      description ?? 'Brak opisu',
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    );
  }
}
