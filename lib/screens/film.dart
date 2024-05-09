import 'package:filman_flutter/model.dart';
import 'package:filman_flutter/screens/player.dart';
import 'package:filman_flutter/types/film_details.dart';
import 'package:filman_flutter/types/season.dart';
import 'package:filman_flutter/widgets/episodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class FilmScreen extends StatefulWidget {
  final String? url, title, image;

  const FilmScreen({super.key, this.url, this.title, this.image});
  @override
  State<FilmScreen> createState() => _FilmScreenState();
}

class _FilmScreenState extends State<FilmScreen> {
  String? get url => widget.url;
  String? get title => widget.title;
  String? get image => widget.image;
  late Future<FilmDetails> lazyFilm;

  void _showBottomSheet(List<Season> seasons) {
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
              child: EpisodesModal(seasons: seasons));
        });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    lazyFilm = Provider.of<FilmanModel>(context, listen: false)
        .getFilmDetails(url ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: lazyFilm,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SafeArea(
                child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(((snapshot.data?.categories.isNotEmpty ?? false)
                          ? snapshot.data?.categories.join(' ').toUpperCase()
                          : "Brak kategorii") ??
                      "Brak kategorii"),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Image.network(
                          image ?? '',
                          width: MediaQuery.of(context).size.width * 0.25,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title ?? '',
                            style: const TextStyle(fontSize: 24),
                          ),
                        )
                      ],
                    )),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Chip(
                        label: Text(
                            snapshot.data?.releaseDate ?? 'Brak informacji'),
                        avatar: const Icon(Icons.calendar_month),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label:
                            Text(snapshot.data?.viewCount ?? 'Brak informacji'),
                        avatar: const Icon(Icons.people),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label:
                            Text(snapshot.data?.country ?? 'Brak informacji'),
                        avatar: const Icon(Icons.flag),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    snapshot.data?.desc ?? 'Brak opisu',
                  ),
                ),
              ]),
            ));
          }
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: Navigator.of(context).pop),
            IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  Share.share("Oglądaj '$title' za darmo na $url");
                }),
            IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                  final Uri uri = Uri.parse(url?.toString() ?? '');
                  if (!await launchUrl(uri,
                      mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not launch')));
                    }
                  }
                }),
          ],
        ),
      ),
      floatingActionButton: FutureBuilder(
        future: lazyFilm,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return FloatingActionButton(
                onPressed: () {}, child: const CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return FloatingActionButton(
                onPressed: () {}, child: const Icon(Icons.error));
          } else {
            return FloatingActionButton(
                child: Icon(snapshot.data?.isSerial ?? false
                    ? Icons.list
                    : Icons.play_arrow),
                onPressed: () async {
                  if (snapshot.data?.isSerial == true) {
                    if (snapshot.data?.seasons?.isNotEmpty ?? false) {
                      _showBottomSheet(snapshot.data?.getSeasons() ?? []);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Brak dostępnych sezonów')));
                      }
                    }
                    if (snapshot.data?.isSerial == false) {
                      String? direct = await snapshot.data?.getDirect();
                      if (direct != null) {
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => FilmanPlayer(
                                    url: direct,
                                  )));
                        }
                      } else {}
                    }
                  }
                });
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
