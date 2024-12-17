// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/types/home_page.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";
import "package:unofficial_filman_client/utils/updater.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:provider/provider.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "dart:math" as math;

class HomePage extends StatefulWidget {
  final Function(bool) onHoverStateChanged;
  
  const HomePage({
    required this.onHoverStateChanged,
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomePageResponse> homePageLoader;
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<FocusNode>> _focusNodes = {};
  final List<FocusScopeNode> _categoryScopeNodes = [];
  int _currentFilmIndex = 0;
  final GlobalKey _mainScrollKey = GlobalKey();
  HomePageResponse? _cachedResponse;
  bool _isActive = true;
  bool _isFirstRowHovered = false;

  static const String recommendedFilms = "Polecane filmy";
  static const String recommendedCategories = "Polecane kategorie";
  
  @override
  void initState() {
    super.initState();
    homePageLoader = _loadHomePage();
    checkForUpdates(context);
  }

void focusFirstElement() {
    if (_focusNodes.isNotEmpty) {
      final firstCategory = _focusNodes.keys.first;
      final firstCategoryNodes = _focusNodes[firstCategory];
      if (firstCategoryNodes != null && firstCategoryNodes.isNotEmpty) {
        setState(() {
          _currentFilmIndex = 0;
          _isFirstRowHovered = true;
          widget.onHoverStateChanged(true);
        });
        firstCategoryNodes[0].requestFocus();
        Future.microtask(() {
          _scrollToVisibleVertical(firstCategory);
          _scrollToVisibleHorizontal(firstCategory, 0);
        });
      }
    }
  }
  void _handleFocusChange(final bool hasFocus) {
    if (mounted && _isActive != hasFocus) {
      setState(() {
        _isActive = hasFocus;
      });
    }
  }

  void _handleFilmFocus(final String category, final int index, final bool hasFocus) {
    if (hasFocus) {
      _handleFocusChange(true);
      setState(() {
        _currentFilmIndex = index;
        final categories = _focusNodes.keys.toList();
        _isFirstRowHovered = categories.isNotEmpty && categories.first == category;
        widget.onHoverStateChanged(_isFirstRowHovered);
      });
    }
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
    final response = await Provider.of<FilmanNotifier>(context, listen: false).getFilmanPage();
    _cachedResponse = response;
    return response;
  }

  void _initializeFocusNodes(final List<String> categories, final HomePageResponse data) {
    if (_focusNodes.isEmpty) {
      for (var category in categories) {
        final films = data.getFilms(category);
        _focusNodes[category] = List.generate(
          films?.length ?? 0,
          (final index) => FocusNode(),
        );
      }
      
      if (_categoryScopeNodes.isEmpty) {
        for (var i = 0; i < categories.length; i++) {
          _categoryScopeNodes.add(FocusScopeNode());
        }
      }
    }
  }

  void _handleKeyEvent(final RawKeyEvent event, final String category, final int filmIndex) {
    if (event is! RawKeyDownEvent) return;

    final categories = _focusNodes.keys.toList();
    final currentCategoryIndex = categories.indexOf(category);
    final currentFilms = _focusNodes[category] ?? [];

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        if (filmIndex < currentFilms.length - 1) {
          setState(() {
            _currentFilmIndex = filmIndex + 1;
          });
          currentFilms[_currentFilmIndex].requestFocus();
          _scrollToVisibleHorizontal(category, _currentFilmIndex);
        }
        break;
      
      case LogicalKeyboardKey.arrowLeft:
        if (filmIndex > 0) {
          setState(() {
            _currentFilmIndex = filmIndex - 1;
          });
          currentFilms[_currentFilmIndex].requestFocus();
          _scrollToVisibleHorizontal(category, _currentFilmIndex);
        }
        break;
      
      case LogicalKeyboardKey.arrowDown:
        if (currentCategoryIndex < categories.length - 1) {
          final nextCategory = categories[currentCategoryIndex + 1];
          final nextFilms = _focusNodes[nextCategory] ?? [];
          if (nextFilms.isNotEmpty) {
            setState(() {
              _currentFilmIndex = math.min(filmIndex, nextFilms.length - 1);
              _isFirstRowHovered = false;
              widget.onHoverStateChanged(false);
            });
            nextFilms[_currentFilmIndex].requestFocus();
            _scrollToVisibleVertical(nextCategory);
          }
        }
        break;
      
      case LogicalKeyboardKey.arrowUp:
        if (currentCategoryIndex > 0) {
          final previousCategory = categories[currentCategoryIndex - 1];
          final previousFilms = _focusNodes[previousCategory] ?? [];
          if (previousFilms.isNotEmpty) {
            setState(() {
              _currentFilmIndex = math.min(filmIndex, previousFilms.length - 1);
              _isFirstRowHovered = currentCategoryIndex == 1;
              widget.onHoverStateChanged(_isFirstRowHovered);
            });
            previousFilms[_currentFilmIndex].requestFocus();
            _scrollToVisibleVertical(previousCategory);
          }
        }
        break;
      
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
        _openFilmDetails(category, filmIndex);
        break;
    }
  }

  void _scrollToVisibleHorizontal(final String category, final int index) {
    final BuildContext? filmContext = _focusNodes[category]?[index].context;
    if (filmContext != null) {
      Scrollable.ensureVisible(
        filmContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToVisibleVertical(final String category) {
    final BuildContext? categoryContext = _focusNodes[category]?[_currentFilmIndex].context;
    if (categoryContext != null) {
      Scrollable.ensureVisible(
        categoryContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openFilmDetails(final String category, final int index) async {
    try {
      Film? selectedFilm;
      
      if (_cachedResponse != null) {
        final films = _cachedResponse!.getFilms(category);
        if (films != null && films.length > index) {
          selectedFilm = films[index];
        }
      }

      if (selectedFilm == null) {
        final response = await Provider.of<FilmanNotifier>(context, listen: false).getFilmanPage();
        final films = response.getFilms(category);
        if (films != null && films.length > index) {
          selectedFilm = films[index];
        }
      }
      
      if (selectedFilm != null && mounted) {
        if (category == recommendedFilms || category == recommendedCategories) {
          final updatedResponse = await Provider.of<FilmanNotifier>(context, listen: false).getFilmanPage();
          _cachedResponse = updatedResponse;
          final updatedFilms = updatedResponse.getFilms(category);
          
          if (updatedFilms != null && updatedFilms.length > index) {
            final updatedFilm = updatedFilms[index];
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (final context) => FilmScreen(
                  url: updatedFilm.link,
                  title: updatedFilm.title,
                  image: updatedFilm.imageUrl,
                ),
              ),
            );
            if (mounted) {
              setState(() {
                homePageLoader = _loadHomePage();
              });
            }
          }
        } else {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (final context) => FilmScreen(
                url: selectedFilm?.link ?? "",
                title: selectedFilm?.title ?? "",
                image: selectedFilm?.imageUrl ?? "",
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd przy otwieraniu filmu: ${e.toString()}")),
        );
      }
    }
  }

  Widget _buildFilmCard(final BuildContext context, final Film film, final String category, final int index) {
    return Focus(
      focusNode: _focusNodes[category]?[index],
      onFocusChange: (final hasFocus) {
        _handleFilmFocus(category, index, hasFocus);
      },
      onKey: (final node, final event) {
        _handleKeyEvent(event, category, index);
        return KeyEventResult.handled;
      },
      child: AnimatedScale(
        scale: _focusNodes[category]?[index].hasFocus == true && _isActive ? 1.1 : 1.0,
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
                  loadingBuilder: (final context, final progress) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (final context, final error, final stackTrace) => const Center(
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

  Widget _buildCategorySection(final BuildContext context, final String category, final HomePageResponse data, final int categoryIndex) {
    final films = data.getFilms(category) ?? [];
    if (films.isEmpty) return const SizedBox.shrink();
    
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
    return FutureBuilder<HomePageResponse>(
      future: homePageLoader,
      builder: (final context, final AsyncSnapshot<HomePageResponse> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return ErrorHandling(
            error: snapshot.error!,
            onLogin: (final auth) => setState(() {
              homePageLoader = _loadHomePage();
            }),
          );
        }

        final categories = snapshot.data?.categories ?? [];
        _initializeFocusNodes(categories, snapshot.data!);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  homePageLoader = _loadHomePage();
                });
              },
              child: CustomScrollView(
                key: _mainScrollKey,
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
    );
  }
}
