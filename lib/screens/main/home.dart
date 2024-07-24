import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/types/home_page.dart";
import "package:unofficial_filman_client/utils/error_handling.dart";
import "package:unofficial_filman_client/utils/updater.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:unofficial_filman_client/utils/titlte.dart";
import "package:unofficial_filman_client/widgets/search.dart";
import "package:provider/provider.dart";

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

  @override
  Widget build(final BuildContext context) {
    return FutureBuilder<HomePageResponse>(
      future: homePageLoader,
      builder:
          (final BuildContext context, final AsyncSnapshot<HomePageResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return buildErrorContent(
              snapshot.error!,
              context,
              (final auth) => setState(() {
                    homePageLoader =
                        Provider.of<FilmanNotifier>(context, listen: false)
                            .getFilmanPage();
                  }));
        }

        return DefaultTabController(
          length: snapshot.data?.getCategories().length ?? 0,
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
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
                          crossAxisCount: (MediaQuery.of(context).size.width ~/
                                  (MediaQuery.of(context).size.height / 2.5)) +
                              1,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8,
                        ),
                        padding: const EdgeInsets.all(10),
                        itemCount:
                            snapshot.data?.getFilms(category)?.length ?? 0,
                        itemBuilder: (final BuildContext context, final int index) {
                          final film =
                              snapshot.data?.getFilms(category)?[index];
                          if (film == null) return const SizedBox();
                          return _buildFilmCard(context, film);
                        },
                      ),
                    ),
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
