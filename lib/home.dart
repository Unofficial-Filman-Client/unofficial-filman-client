import 'package:filman_flutter/film.dart';
import 'package:filman_flutter/login.dart';
import 'package:filman_flutter/model.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<Response> lazyDocument;
  late Future<Response> lazySearch;
  late final TextEditingController searchController;
  String lastSearch = '';
  Set<String> categories = {};

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    lazySearch = Future.value(Response(
        data: '', statusCode: 200, requestOptions: RequestOptions(path: '')));
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      lazyDocument =
          Provider.of<FilmanModel>(context, listen: false).getFilmanPage();
    });
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
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    SearchBar(
                      controller: searchController,
                      padding: const MaterialStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0)),
                      leading: const Icon(Icons.search),
                      autoFocus: true,
                      onChanged: (value) {
                        if (value.isNotEmpty && value != lastSearch) {
                          setState(() {
                            lastSearch = value;
                            lazySearch =
                                Provider.of<FilmanModel>(context, listen: false)
                                    .searchInFilman(value);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: searchController.text.isNotEmpty
                          ? FutureBuilder(
                              future: lazySearch,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Container(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(context)
                                            .viewInsets
                                            .bottom,
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Wystąpił błąd podczas wyszukiwania",
                                        ),
                                      ));
                                } else if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  final document = parse(snapshot.data?.data);

                                  final films = document.querySelectorAll(
                                      '.col-xs-6.col-sm-3.col-lg-2');

                                  List<Widget> filmWidgets = [];

                                  for (final film in films) {
                                    final poster =
                                        film.querySelector('.poster');
                                    final title = film
                                        .querySelector('.film_title')
                                        ?.text
                                        .trim();
                                    final desc = poster
                                        ?.querySelector('a')
                                        ?.attributes['data-text']
                                        ?.trim();
                                    final releaseDate = film
                                        .querySelector('.film_year')
                                        ?.text
                                        .trim();
                                    final imageUrl = poster
                                        ?.querySelector('img')
                                        ?.attributes['src']
                                        ?.trim();
                                    final qualityVersion = poster
                                        ?.querySelector('a .quality-version')
                                        ?.text
                                        .trim();
                                    final rating = poster
                                        ?.querySelector('a .rate')
                                        ?.text
                                        .trim();
                                    final link = poster
                                        ?.querySelector('a')
                                        ?.attributes['href'];

                                    final filmObj = {
                                      'title': title,
                                      'desc': desc,
                                      'releaseDate': releaseDate,
                                      'imageUrl': imageUrl,
                                      'qualityVersion': qualityVersion,
                                      'rating': rating,
                                      'link': link,
                                    };

                                    filmWidgets.add(
                                      Card(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 3.0),
                                        child: ListTile(
                                          title: Text(filmObj['title'] ?? ''),
                                          subtitle: Text(filmObj['desc'] ?? ''),
                                          leading: Image.network(
                                              filmObj['imageUrl'] ?? ''),
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FilmScreen(
                                                  url: filmObj["link"],
                                                  title: filmObj["title"],
                                                  image: filmObj["imageUrl"],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  return ListView(
                                    children: filmWidgets.isNotEmpty
                                        ? [
                                            ...filmWidgets,
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom,
                                            )
                                          ]
                                        : [const Text("Brak wyników")],
                                  );
                                }
                                return const Text("Brak wyników");
                              })
                          : Container(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: Center(
                                child: Text(
                                    "Rozpocznij wyszukiwanie a wyniki pojawią się tutaj",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium),
                              ),
                            ),
                    ),
                  ],
                ),
              ));
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: lazyDocument,
      builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to Filman!'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () {
                        // Handle settings action
                      },
                      icon: const Icon(Icons.settings),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () {
                        Provider.of<FilmanModel>(context, listen: false)
                            .logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ),
                ],
                automaticallyImplyLeading: false,
                bottom: PreferredSize(
                    preferredSize: Size(MediaQuery.of(context).size.width, 50),
                    child: const LinearProgressIndicator()),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final document = parse(snapshot.data!.data);

          final output = {};
          final Set<String> finalCategories = {};

          document.querySelectorAll('div[id=item-list]').forEach((list) {
            for (final film in list.children) {
              final poster = film.querySelector('.poster');
              final title = poster?.querySelector('a')?.attributes['title'];
              final desc = poster?.querySelector('a')?.attributes['data-text'];
              final imageUrl = poster?.querySelector('img')?.attributes['src'];
              final qualityVersion =
                  poster?.querySelector('.quality-version')?.text.trim();
              final viewCount = poster?.querySelector('.view')?.text.trim();
              final link = poster?.querySelector('a')?.attributes['href'];

              final filmObj = {
                'title': title,
                'desc': desc,
                'imageUrl': imageUrl,
                'qualityVersion': qualityVersion,
                'viewCount': viewCount,
                'link': link,
              };

              final category =
                  list.parent?.querySelector("h3")?.text.trim() ?? "INNE";
              if (output[category] == null) output[category] = [];
              output[category].add(filmObj);
              finalCategories.add(category);
            }
          });

          return DefaultTabController(
            length: finalCategories.length,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to Filman!'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () {
                        // Handle settings action
                      },
                      icon: const Icon(Icons.settings),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () {
                        Provider.of<FilmanModel>(context, listen: false)
                            .logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                    ),
                  ),
                ],
                automaticallyImplyLeading: false,
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: [
                    for (final category in finalCategories)
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
                    for (final category in output.values)
                      RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          children: [
                            const SizedBox(height: 3.0),
                            for (final film in category)
                              Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 3.0),
                                child: ListTile(
                                  title: Text(film['title'] ?? ''),
                                  subtitle: Text(film['desc'] ?? ''),
                                  leading:
                                      Image.network(film['imageUrl'] ?? ''),
                                  onTap: () async {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => FilmScreen(
                                          url: film["link"],
                                          title: film["title"],
                                          image: film["imageUrl"],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  _showBottomSheet();
                },
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
        }
      },
    );
  }
}
