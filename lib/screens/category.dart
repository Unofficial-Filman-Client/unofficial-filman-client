import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/category.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";

class MoviesScreen extends StatelessWidget {
  final Category category;
  final List<Film> movies;
  const MoviesScreen({super.key, required this.category, required this.movies});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          mainAxisExtent: 250,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: movies.length,
        itemBuilder: (final context, final index) {
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (final context) => FilmScreen(
                    url: movies[index].link,
                    title: movies[index].title,
                    image: movies[index].imageUrl,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              child: FastCachedImage(
                url: movies[index].imageUrl,
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
              ),
            ),
          );
        },
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

  const CategoryCard({
    super.key,
    required this.category,
    required this.films,
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
              movies: loadedFilms,
            ),
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
