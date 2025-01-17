import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/category.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";

class MoviesScreen extends StatefulWidget {
  final Category category;
  final List<Film> initialMovies;
  final bool forSeries;

  const MoviesScreen({
    super.key,
    required this.category,
    required this.initialMovies,
    required this.forSeries,
  });

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Film> _movies = [];
  bool _isLoading = false;
  bool _hasMoreMovies = true;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _movies = List.from(widget.initialMovies);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreMovies) {
      _loadMoreMovies();
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _page++;
    });

    try {
      final filmanNotifier =
          Provider.of<FilmanNotifier>(context, listen: false);
      final newMovies = await filmanNotifier.getMoviesByCategory(
        widget.category,
        widget.forSeries,
        page: _page,
      );

      setState(() {
        if (newMovies.isEmpty) {
          _hasMoreMovies = false;
        } else {
          _movies.addAll(newMovies);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                mainAxisExtent: 250,
              ),
              padding: const EdgeInsets.all(10),
              itemCount: _movies.length + (_isLoading ? 2 : 0),
              itemBuilder: (final context, final index) {
                if (index >= _movies.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (final context) => FilmScreen(
                          url: _movies[index].link,
                          title: _movies[index].title,
                          image: _movies[index].imageUrl,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                    child: FastCachedImage(
                      url: _movies[index].imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (final context, final progress) =>
                          SizedBox(
                        height: 180,
                        width: 116,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.progressPercentage.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryScreen extends StatefulWidget {
  final bool forSeries;
  const CategoryScreen({super.key, required this.forSeries});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Category>> categoryLoader;

  @override
  void initState() {
    super.initState();
    categoryLoader =
        Provider.of<FilmanNotifier>(context, listen: false).getCategories();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kategorie ${widget.forSeries ? "seriali" : "filmów"}"),
      ),
      body: FutureBuilder(
        future: categoryLoader,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorHandling(
              error: snapshot.error!,
              onLogin: (final response) =>
                  Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (final context) => CategoryScreen(
                    forSeries: widget.forSeries,
                  ),
                ),
              ),
            );
          }

          final List<Category> categories = snapshot.data as List<Category>;

          final filmFutures = <int, Future<List<Film>>>{};
          for (var i = 0; i < categories.length; i++) {
            filmFutures[i] = Provider.of<FilmanNotifier>(context, listen: false)
                .getMoviesByCategory(categories[i], widget.forSeries);
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              mainAxisExtent: 250,
            ),
            padding: const EdgeInsets.all(10),
            itemCount: categories.length,
            itemBuilder: (final context, final index) {
              return CategoryCard(
                category: categories[index],
                films: filmFutures[index]!,
                forSeries: widget.forSeries,
              );
            },
          );
        },
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final Future<List<Film>> films;
  final bool forSeries;

  const CategoryCard({
    super.key,
    required this.category,
    required this.films,
    required this.forSeries,
  });

  @override
  Widget build(final BuildContext context) {
    List<Film> loadedFilms = [];
    return InkWell(
      onTap: () {
        if (loadedFilms.isEmpty) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (final context) => MoviesScreen(
                category: category,
                initialMovies: loadedFilms,
                forSeries: forSeries),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<List<Film>>(
              future: films,
              builder: (final context, final snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Icon(Icons.error));
                }
                loadedFilms = snapshot.data ?? [];
                return FastCachedImage(
                  url: snapshot.data?.firstOrNull?.imageUrl ??
                      "https://placehold.co/250x370/png?font=roboto&text=?",
                  fit: BoxFit.cover,
                  loadingBuilder: (final context, final progress) => SizedBox(
                    height: 180,
                    width: 116,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.progressPercentage.value,
                      ),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Text(
                category.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ]),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
