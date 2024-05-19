import 'package:filman_flutter/notifiers/settings.dart';
import 'package:filman_flutter/screens/film.dart';
import 'package:filman_flutter/screens/login.dart';
import 'package:filman_flutter/notifiers/filman.dart';
import 'package:filman_flutter/screens/settings.dart';
import 'package:filman_flutter/types/exceptions.dart';
import 'package:filman_flutter/types/film.dart';
import 'package:filman_flutter/types/home_page.dart';
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
              child: const SearchModal());
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: homePageLoader,
      builder: (BuildContext context, AsyncSnapshot<HomePage> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to Filman!'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () {
                        Provider.of<FilmanNotifier>(context, listen: false)
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
                    preferredSize: Size(MediaQuery.of(context).size.width, 49),
                    child: const LinearProgressIndicator()),
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ));
        } else if (snapshot.hasError) {
          if (snapshot.error is LogOutException) {
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
                  builder: (context) => const LoginScreen(),
                ),
              );
            });
          }
          return Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to Filman!'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () {
                        Provider.of<FilmanNotifier>(context, listen: false)
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
              body: Center(
                child: Text(
                    "Wystąpił błąd podczas ładowania strony (${snapshot.error})"),
              ));
        } else {
          final double screenWidth = MediaQuery.of(context).size.width;
          return DefaultTabController(
            length: snapshot.data?.categories.length ?? 0,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Welcome to Filman!'),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16.0),
                    child: IconButton(
                      onPressed: () {
                        Provider.of<FilmanNotifier>(context, listen: false)
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
                            homePageLoader = Provider.of<FilmanNotifier>(
                                    context,
                                    listen: false)
                                .getFilmanPage();
                          });
                        },
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth > 1024 ? 3 : 2,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.8,
                          ),
                          padding: const EdgeInsets.all(10),
                          itemCount:
                              snapshot.data?.getFilms(category)?.length ?? 0,
                          itemBuilder: (BuildContext context, int index) {
                            Film? film =
                                snapshot.data?.getFilms(category)?[index];
                            if (film == null) return const SizedBox();
                            return Card(
                              child: InkWell(
                                onTap: () async {
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(4.0)),
                                        child: Image.network(
                                          film.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Consumer<SettingsNotifier>(
                                              builder:
                                                  (context, value, child) =>
                                                      Text(
                                                film.title.contains("/")
                                                    ? value.titleType ==
                                                            TitleDisplayType
                                                                .first
                                                        ? film.title
                                                            .split('/')
                                                            .first
                                                        : value.titleType ==
                                                                TitleDisplayType
                                                                    .second
                                                            ? film.title
                                                                .split('/')[1]
                                                            : film.title
                                                    : film.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                ),
                                                maxLines:
                                                    screenWidth > 1024 ? 3 : 2,
                                                overflow: TextOverflow.fade,
                                                textAlign: TextAlign.center,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
