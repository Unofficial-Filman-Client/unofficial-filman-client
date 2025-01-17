// ignore_for_file: deprecated_member_use

import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/types/home_page.dart";
import "package:unofficial_filman_client/utils/updater.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:provider/provider.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "dart:math" as math;

class HomePage extends StatefulWidget {
  final Function(bool) onHoverStateChanged;

  const HomePage({required this.onHoverStateChanged, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomePageResponse> homePageLoader;
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<FocusNode>> _focusNodes = {};
  final List<FocusScopeNode> _categoryScopeNodes = [];
  int _currentFilmIndex = 0;
  HomePageResponse? _cachedResponse;
  bool _isActive = true;
  bool _isFirstRowHovered = false;

  static const String recommendedFilms = "Polecane filmy";
  static const String recommendedCategories = "Polecane kategorie";

  @override
  void initState() {
    super.initState();
    homePageLoader = _loadHomePage();
    checkForUpdates();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var nodeList in _focusNodes.values) {
      for (var node in nodeList) {
        node.dispose();
      }
    }
    for (var node in _categoryScopeNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<HomePageResponse> _loadHomePage() async {
    final response = await Provider.of<FilmanNotifier>(context, listen: false)
        .getFilmanPage();
    _cachedResponse = response;
    return response;
  }

  void _initializeFocusNodes(
      final List<String> categories, final HomePageResponse data) {
    if (_focusNodes.isEmpty) {
      for (var category in categories) {
        final films = data.getFilms(category);
        _focusNodes[category] =
            List.generate(films?.length ?? 0, (final _) => FocusNode());
      }

      if (_categoryScopeNodes.isEmpty) {
        _categoryScopeNodes.addAll(
            List.generate(categories.length, (final _) => FocusScopeNode()));
      }
    }
  }

  void _handleKeyEvent(
      final RawKeyEvent event, final String category, final int filmIndex) {
    if (event is! RawKeyDownEvent) return;

    final categories = _focusNodes.keys.toList();
    final currentCategoryIndex = categories.indexOf(category);
    final currentFilms = _focusNodes[category] ?? [];

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        if (filmIndex < currentFilms.length - 1) {
          setState(() => _currentFilmIndex = filmIndex + 1);
          currentFilms[_currentFilmIndex].requestFocus();
          _scrollToFilm(category, _currentFilmIndex);
        }
        break;

      case LogicalKeyboardKey.arrowLeft:
        if (filmIndex > 0) {
          setState(() => _currentFilmIndex = filmIndex - 1);
          currentFilms[_currentFilmIndex].requestFocus();
          _scrollToFilm(category, _currentFilmIndex);
        }
        break;

      case LogicalKeyboardKey.arrowDown:
        if (currentCategoryIndex < categories.length - 1) {
          _moveToCategory(
              categories[currentCategoryIndex + 1], filmIndex, false);
        }
        break;

      case LogicalKeyboardKey.arrowUp:
        if (currentCategoryIndex > 0) {
          _moveToCategory(categories[currentCategoryIndex - 1], filmIndex,
              currentCategoryIndex == 1);
        }
        break;

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        _openFilmDetails(category, filmIndex);
        break;

      case LogicalKeyboardKey.browserBack:
      case LogicalKeyboardKey.goBack:
        Navigator.of(context).maybePop();
        break;
    }
  }

  void _moveToCategory(
      final String category, final int currentIndex, final bool isFirstRow) {
    final films = _focusNodes[category] ?? [];
    if (films.isNotEmpty) {
      setState(() {
        _currentFilmIndex = math.min(currentIndex, films.length - 1);
        _isFirstRowHovered = isFirstRow;
        widget.onHoverStateChanged(isFirstRow);
      });
      films[_currentFilmIndex].requestFocus();
      _scrollToCategory(category);
    }
  }

  void _scrollToFilm(final String category, final int index) {
    final context = _focusNodes[category]?[index].context;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCategory(final String category) {
    final context = _focusNodes[category]?[_currentFilmIndex].context;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openFilmDetails(final String category, final int index) async {
    try {
      Film? selectedFilm = _getFilm(category, index);

      if (selectedFilm == null) {
        final response =
            await Provider.of<FilmanNotifier>(context, listen: false)
                .getFilmanPage();
        selectedFilm = response.getFilms(category)?[index];
      }

      if (selectedFilm != null && mounted) {
        if (category == recommendedFilms || category == recommendedCategories) {
          await _handleRecommendedFilm(category, index);
        } else {
          await _navigateToFilm(selectedFilm);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Błąd przy otwieraniu filmu: $e")));
      }
    }
  }

  Film? _getFilm(final String category, final int index) {
    return _cachedResponse?.getFilms(category)?[index];
  }

  Future<void> _handleRecommendedFilm(
      final String category, final int index) async {
    final updatedResponse =
        await Provider.of<FilmanNotifier>(context, listen: false)
            .getFilmanPage();
    _cachedResponse = updatedResponse;
    final film = updatedResponse.getFilms(category)?[index];

    if (film != null && mounted) {
      await _navigateToFilm(film);
      if (mounted) {
        setState(() => homePageLoader = _loadHomePage());
      }
    }
  }

  Future<void> _navigateToFilm(final Film film) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final context) => FilmScreen(
          url: film.link,
          title: film.title,
          image: film.imageUrl,
        ),
      ),
    );
  }

  Widget _buildFilmCard(final BuildContext context, final Film film,
      final String category, final int index) {
    return Focus(
      focusNode: _focusNodes[category]?[index],
      onFocusChange: (final hasFocus) {
        if (hasFocus) {
          setState(() {
            _isActive = true;
            _currentFilmIndex = index;
            _isFirstRowHovered = _focusNodes.keys.firstOrNull == category;
            widget.onHoverStateChanged(_isFirstRowHovered);
          });
        }
      },
      onKey: (final _, final event) {
        _handleKeyEvent(event, category, index);
        return KeyEventResult.handled;
      },
      child: AnimatedScale(
        scale: _focusNodes[category]?[index].hasFocus == true && _isActive
            ? 1.1
            : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 116,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNodes[category]?[index].hasFocus == true && _isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: GestureDetector(
            onTap: () => _openFilmDetails(category, index),
            child: Card(
              margin: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                child: FastCachedImage(
                  url: film.imageUrl,
                  fit: BoxFit.cover,
                  height: 180,
                  width: 116,
                  loadingBuilder: (final _, final __) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (final _, final __, final ___) => const Center(
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      final BuildContext context,
      final String category,
      final HomePageResponse data,
      final int categoryIndex) {
    final films = data.getFilms(category);
    if (films == null || films.isEmpty) return const SizedBox.shrink();

    return FocusScope(
      node: _categoryScopeNodes[categoryIndex],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            SizedBox(
              height: 186,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: films.length,
                itemBuilder: (final context, final index) => _buildFilmCard(
                  context,
                  films[index],
                  category,
                  index,
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
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        }
        SystemNavigator.pop();
        return false;
      },
      child: FutureBuilder<HomePageResponse>(
        future: homePageLoader,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return ErrorHandling(
              error: snapshot.error!,
              onLogin: (final auth) =>
                  setState(() => homePageLoader = _loadHomePage()),
            );
          }

          final categories = snapshot.data?.categories ?? [];
          _initializeFocusNodes(categories, snapshot.data!);

          return Scaffold(
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => homePageLoader = _loadHomePage());
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (final context, final index) {
                          if (index >= categories.length) return null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildCategorySection(
                              context,
                              categories[index],
                              snapshot.data!,
                              index,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
