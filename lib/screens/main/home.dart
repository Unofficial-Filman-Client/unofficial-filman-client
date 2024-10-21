import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/types/home_page.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";
import "package:unofficial_filman_client/utils/updater.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:unofficial_filman_client/widgets/search.dart";
import "package:provider/provider.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Future<HomePageResponse> homePageLoader;

  @override
  void initState() {
    super.initState();
    homePageLoader =
        Provider.of<FilmanNotifier>(context, listen: false).getFilmanPage();
    checkForUpdates(context);
  }

  void _showBottomSheet() {
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
          child: const SearchModal(),
        );
      },
    );
  }

  Widget _buildFilmCard(final BuildContext context, final Film film) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (final context) => FilmScreen(
                url: film.link,
                title: film.title,
                image: film.imageUrl,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          child: FastCachedImage(
              url: film.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (final context, final progress) => SizedBox(
                    height: 180,
                    width: 116,
                    child: Center(
                      child: CircularProgressIndicator(
                          value: progress.progressPercentage.value),
                    ),
                  )),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<HomePageResponse>(
      future: homePageLoader,
      builder: (final BuildContext context,
          final AsyncSnapshot<HomePageResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return ErrorHandling(
              error: snapshot.error!,
              onLogin: (final auth) => setState(() {
                    homePageLoader =
                        Provider.of<FilmanNotifier>(context, listen: false)
                            .getFilmanPage();
                  }));
        }

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
              child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                homePageLoader =
                    Provider.of<FilmanNotifier>(context, listen: false)
                        .getFilmanPage();
              });
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (final String category
                        in snapshot.data?.categories ?? [])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20),
                            ),
                            SizedBox(
                              height: 180.0,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final Film film
                                      in snapshot.data?.getFilms(category) ??
                                          [])
                                    _buildFilmCard(context, film),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )),
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
        );
      },
    );
  }
}
