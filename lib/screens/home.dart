import 'package:filman_flutter/notifiers/watched.dart';
import 'package:filman_flutter/screens/film.dart';
import 'package:filman_flutter/screens/hello.dart';
import 'package:filman_flutter/notifiers/filman.dart';
import 'package:filman_flutter/screens/player.dart';
import 'package:filman_flutter/screens/settings.dart';
import 'package:filman_flutter/types/exceptions.dart';
import 'package:filman_flutter/types/film.dart';
import 'package:filman_flutter/types/home_page.dart';
import 'package:filman_flutter/types/watched.dart';
import 'package:filman_flutter/utils/titlte.dart';
import 'package:filman_flutter/widgets/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<HomePage> homePageLoader;

  @override
  void initState() {
    super.initState();
    homePageLoader =
        Provider.of<FilmanNotifier>(context, listen: false).getFilmanPage();
  }

  void _showBottomSheet() {
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
          child: const SearchModal(),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, {bool showProgress = false}) {
    return AppBar(
      title: const Text('Welcome to Filman!'),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.settings),
        ),
        IconButton(
          onPressed: () {
            Provider.of<FilmanNotifier>(context, listen: false).logout();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HelloScreen(),
              ),
            );
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      automaticallyImplyLeading: false,
      bottom: showProgress
          ? const PreferredSize(
              preferredSize: Size.fromHeight(4.0),
              child: LinearProgressIndicator(),
            )
          : null,
    );
  }

  Widget _buildErrorContent(Object error) {
    if (error is LogOutException) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nastąpiło wylogowanie!'),
            dismissDirection: DismissDirection.horizontal,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HelloScreen(),
          ),
        );
      });
      return const SizedBox.shrink();
    }

    return Center(
      child: Text("Wystąpił błąd podczas ładowania strony ($error)"),
    );
  }

  Widget _buildFilmCard(BuildContext context, Film film) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FilmScreen(
                url: film.link,
                title: film.title,
                image: film.imageUrl,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4.0)),
                child: Image.network(
                  film.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DisplayTitle(
                      title: film.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                      maxLines:
                          MediaQuery.of(context).size.width > 1024 ? 3 : 2,
                      overflow: TextOverflow.fade,
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchedFilmCard(
      BuildContext context, WatchedSingle film, WatchedNotifier all) {
    return Card(
      child: InkWell(
        onTap: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => FilmanPlayer.fromDetails(
                      filmDetails: film.filmDetails,
                      startFrom: film.watchedInSec,
                      savedDuration: film.totalInSec,
                    )),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4.0)),
                child: Image.network(
                  film.filmDetails.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            LinearProgressIndicator(
              value: film.watchedInSec / film.totalInSec,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DisplayTitle(
                        title: film.filmDetails.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                        maxLines:
                            MediaQuery.of(context).size.width > 1024 ? 3 : 2,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.center,
                      ),
                      film.filmDetails.isEpisode
                          ? Column(
                              children: [
                                Text((film.filmDetails.seasonEpisodeTag
                                            ?.split(' ')
                                          ?..removeAt(0))
                                        ?.join(' ') ??
                                    ''),
                                Text(
                                  'S${film.parentSeason?.seasonTitle.replaceAll('Sezon ', '')}:O${1 + (film.parentSeason?.episodes.indexWhere((e) => e.episodeUrl == film.filmDetails.url) ?? 0)} z ${film.parentSeason?.episodes.length}',
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Text('Pozostało: ${film.totalInSec ~/ 60} min'),
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<HomePage>(
      future: homePageLoader,
      builder: (BuildContext context, AsyncSnapshot<HomePage> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: _buildAppBar(context, showProgress: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(context, showProgress: true),
            body: _buildErrorContent(snapshot.error!),
          );
        }

        return DefaultTabController(
          length: (snapshot.data?.categories.length ?? 0) + 1,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Welcome to Filman!'),
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                ),
                IconButton(
                  onPressed: () {
                    Provider.of<FilmanNotifier>(context, listen: false)
                        .logout();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HelloScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
              automaticallyImplyLeading: false,
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: [
                  for (final category in snapshot.data?.getCategories() ?? [])
                    Tab(
                      child: Text(
                        category,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const Text(
                    "OGLĄDANE",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: TabBarView(
                children: [
                  for (final category in snapshot.data?.getCategories() ?? [])
                    RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          homePageLoader = Provider.of<FilmanNotifier>(context,
                                  listen: false)
                              .getFilmanPage();
                        });
                      },
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 1024 ? 3 : 2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        padding: const EdgeInsets.all(10),
                        itemCount:
                            snapshot.data?.getFilms(category)?.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          final film =
                              snapshot.data?.getFilms(category)?[index];
                          if (film == null) return const SizedBox();
                          return _buildFilmCard(context, film);
                        },
                      ),
                    ),
                  Consumer<WatchedNotifier>(
                    builder: (context, value, child) {
                      List<WatchedSingle> combined = value.films +
                          value.serials.map((e) => e.episodes.last).toList();
                      combined
                          .sort((a, b) => b.watchedAt.compareTo(a.watchedAt));

                      return (GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth > 1024 ? 3 : 2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        padding: const EdgeInsets.all(10),
                        itemCount: combined.length,
                        itemBuilder: (BuildContext context, int index) {
                          final film = combined[index];
                          return _buildWatchedFilmCard(context, film, value);
                        },
                      ));
                    },
                  )
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showBottomSheet,
              label: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8.0),
                  Text("Szukaj"),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
