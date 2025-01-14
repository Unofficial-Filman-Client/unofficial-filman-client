// ignore_for_file: constant_identifier_names, deprecated_member_use

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/category.dart";
import "package:unofficial_filman_client/types/film.dart";
import "package:unofficial_filman_client/widgets/error_handling.dart";

class CategoryScreen extends StatefulWidget {
  final bool forSeries;
  const CategoryScreen({super.key, required this.forSeries});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Category>> categoryLoader;
  int selectedCategoryIndex = 0;
  final ScrollController _categoriesScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();
  final FocusNode _backButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    categoryLoader =
        Provider.of<FilmanNotifier>(context, listen: false).getCategories();
  }

  @override
  void dispose() {
    _categoriesScrollController.dispose();
    _gridScrollController.dispose();
    _backButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: categoryLoader,
        builder: (final context, final snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorHandling(
              error: snapshot.error!,
              onLogin: (final response) => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (final context) =>
                      CategoryScreen(forSeries: widget.forSeries),
                ),
              ),
            );
          }

          final List<Category> categories = snapshot.data as List<Category>;
          return NetflixStyleLayout(
            categories: categories,
            selectedIndex: selectedCategoryIndex,
            onCategoryChanged: (final index) {
              setState(() {
                selectedCategoryIndex = index;
              });
              _categoriesScrollController.animateTo(
                index * 100.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            forSeries: widget.forSeries,
            categoriesScrollController: _categoriesScrollController,
            gridScrollController: _gridScrollController,
            backButtonFocusNode: _backButtonFocusNode,
          );
        },
      ),
    );
  }
}

class NetflixStyleLayout extends StatelessWidget {
  final List<Category> categories;
  final int selectedIndex;
  final Function(int) onCategoryChanged;
  final bool forSeries;
  final ScrollController categoriesScrollController;
  final ScrollController gridScrollController;
  final FocusNode backButtonFocusNode;

  static const double BUTTON_WIDTH = 150.0;
  static const double HORIZONTAL_PADDING = 16.0;
  static const double BUTTON_SPACING = 16.0;

  const NetflixStyleLayout({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategoryChanged,
    required this.forSeries,
    required this.categoriesScrollController,
    required this.gridScrollController,
    required this.backButtonFocusNode,
  });

  void _scrollToCategory(final BuildContext context, final int index, {final bool animate = true}) {
    if (!categoriesScrollController.hasClients) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double centerPosition = screenWidth / 2;
    
    final double targetPosition = (BUTTON_WIDTH + BUTTON_SPACING) * index;
    double offset = targetPosition - centerPosition + (BUTTON_WIDTH / 2);
    final maxScroll = categoriesScrollController.position.maxScrollExtent;
    offset = offset.clamp(0.0, maxScroll);

    if (animate) {
      categoriesScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      categoriesScrollController.jumpTo(offset);
    }
  }

 @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Row(
            children: [
              Focus(
                focusNode: backButtonFocusNode,
                onKey: (node, event) {
                  if (event is RawKeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      final FocusScopeNode scope = FocusScope.of(context);
                      final categoryButtons = scope.traversalDescendants
                          .where((element) =>
                              element.context?.findAncestorWidgetOfExactType<CategoryButton>() != null)
                          .toList();

                      final targetButton = categoryButtons.firstWhere(
                        (element) {
                          final categoryButton = element.context?.findAncestorWidgetOfExactType<CategoryButton>();
                          return categoryButton != null && 
                                 (categoryButton as CategoryButton).index == selectedIndex;
                        },
                        orElse: () => categoryButtons.first,
                      );

                      targetButton.requestFocus();
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: BackButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ButtonStyle(
                    iconSize: MaterialStateProperty.all(32),
                  ),
                ),
              ),
              Text(
                forSeries ? "Kategoria: Seriale" : "Kategoria: Filmy",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        FocusTraversalGroup(
          child: SizedBox(
            height: 50,
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: LayoutBuilder(
                builder: (final context, final constraints) {
                  return ListView.builder(
                    controller: categoriesScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: HORIZONTAL_PADDING),
                    itemCount: categories.length,
                    itemBuilder: (final context, final index) {
                      return Container(
                        width: BUTTON_WIDTH,
                        margin: const EdgeInsets.only(right: BUTTON_SPACING),
                        child: CategoryButton(
                          category: categories[index],
                          isSelected: index == selectedIndex,
                          onPressed: () {
                            onCategoryChanged(index);
                            _scrollToCategory(context, index);
                          },
                          autofocus: index == selectedIndex,
                          index: index,
                          onFocusFromGrid: () {
                            _scrollToCategory(context, selectedIndex, animate: false);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: FocusTraversalGroup(
            child: PageStorage(
              bucket: PageStorageBucket(),
              child: CategoryContent(
                key: PageStorageKey('${categories[selectedIndex].name}_$forSeries'),
                category: categories[selectedIndex],
                forSeries: forSeries,
                gridScrollController: gridScrollController,
                currentCategoryIndex: selectedIndex,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryButton extends StatefulWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool autofocus;
  final VoidCallback? onFocusFromGrid;
  final int index;

  const CategoryButton({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onPressed,
    this.autofocus = false,
    this.onFocusFromGrid,
    required this.index,
  });

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  bool isFocused = false;
  bool isHovered = false;

  @override
  Widget build(final BuildContext context) {
    final isHighlighted = isFocused || widget.isSelected || isHovered;
    final scale = isHighlighted ? 1.1 : 1.0;

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (final focused) {
        setState(() {
          isFocused = focused;
        });
        if (focused) {
          widget.onPressed();
        }
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final FocusScopeNode scope = FocusScope.of(context);
            final movieTileFocus = scope.traversalDescendants
                .where((final element) => 
                    element.context?.findAncestorWidgetOfExactType<MovieTile>() != null)
                .firstOrNull;
            
            if (movieTileFocus != null) {
              movieTileFocus.requestFocus();
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            final FocusScopeNode scope = FocusScope.of(context);
            final backButton = scope.traversalDescendants
                .where((final element) => 
                    element.context?.findAncestorWidgetOfExactType<BackButton>() != null)
                .firstOrNull;
            
            if (backButton != null) {
              backButton.requestFocus();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) {
          setState(() {
            isHovered = true;
            widget.onPressed();
          });
        },
        onExit: (final _) => setState(() => isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(scale),
          child: TextButton(
            onPressed: widget.onPressed,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.transparent),
              padding: MaterialStateProperty.all(EdgeInsets.zero),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
            ),
            child: Text(
              widget.category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isHighlighted ? Colors.white : Colors.grey,
                fontSize: isHighlighted ? 18 : 16,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryContent extends StatefulWidget {
  final Category category;
  final bool forSeries;
  final ScrollController gridScrollController;
  final int currentCategoryIndex;
  final Function(int)? onCategoryChange;

  const CategoryContent({
    super.key,
    required this.category,
    required this.forSeries,
    required this.gridScrollController,
    required this.currentCategoryIndex,
    this.onCategoryChange,
  });

  @override
  State<CategoryContent> createState() => _CategoryContentState();
}

class _CategoryContentState extends State<CategoryContent> with AutomaticKeepAliveClientMixin {
  late Future<List<Film>> _filmsFuture;
  Map<String, List<Film>> _cachedFilms = {};
  static const int itemsPerRow = 6;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _filmsFuture = _loadFilms();
  }

  Future<List<Film>> _loadFilms() async {
    final cacheKey = '${widget.category.name}_${widget.forSeries}';
    if (_cachedFilms.containsKey(cacheKey)) {
      return _cachedFilms[cacheKey]!;
    }

    final films = await Provider.of<FilmanNotifier>(context, listen: false)
        .getMoviesByCategory(widget.category, widget.forSeries);
    _cachedFilms[cacheKey] = films;
    return films;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<Film>>(
      future: _filmsFuture,
      builder: (final context, final snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Icon(Icons.error));
        }

        final films = snapshot.data ?? [];

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          controller: widget.gridScrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemsPerRow,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 2/3,
          ),
          itemCount: films.length,
          itemBuilder: (final context, final index) => MovieTile(
            film: films[index],
            autofocus: index == 0,
            gridController: widget.gridScrollController,
            index: index,
            itemsPerRow: itemsPerRow,
            totalItems: films.length,
            onCategoryChange: widget.onCategoryChange,
            currentCategoryIndex: widget.currentCategoryIndex,
          ),
        );
      },
    );
  }
}

class MovieTile extends StatefulWidget {
  final Film film;
  final bool autofocus;
  final ScrollController gridController;
  final int index;
  final int itemsPerRow;
  final int totalItems;
  final Function(int)? onCategoryChange;
  final int currentCategoryIndex;

  const MovieTile({
    super.key,
    required this.film,
    required this.gridController,
    required this.index,
    required this.itemsPerRow,
    required this.totalItems,
    this.onCategoryChange,
    this.autofocus = false,
    required this.currentCategoryIndex,
  });

  @override
  State<MovieTile> createState() => _MovieTileState();
}

class _MovieTileState extends State<MovieTile> {
  bool isFocused = false;
  bool isHovered = false;
  FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _scrollToVisible() {
    if (!widget.gridController.hasClients) return;
    final BuildContext? itemContext = focusNode.context;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleFilmSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final context) => FilmScreen(
          url: widget.film.link,
          title: widget.film.title,
          image: widget.film.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final scale = (isFocused || isHovered) ? 1.05 : 1.0;
    final elevation = (isFocused || isHovered) ? 8.0 : 1.0;

    return Focus(
      focusNode: focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (final focused) {
        setState(() {
          isFocused = focused;
        });
        if (focused) {
          Future.delayed(const Duration(milliseconds: 50), _scrollToVisible);
        }
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (widget.index < widget.itemsPerRow) {
              final FocusScopeNode scope = FocusScope.of(context);
              final categoryButtons = scope.traversalDescendants
                  .where((element) =>
                      element.context?.findAncestorWidgetOfExactType<CategoryButton>() != null)
                  .toList();

              final specificCategoryButton = categoryButtons.firstWhere(
                (element) {
                  final categoryButton =
                      element.context?.findAncestorWidgetOfExactType<CategoryButton>();
                  return categoryButton != null &&
                      (categoryButton as CategoryButton).index == widget.currentCategoryIndex;
                },
                orElse: () => categoryButtons.first,
              );

              specificCategoryButton.requestFocus();
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (widget.index + widget.itemsPerRow < widget.totalItems) {
              FocusScope.of(context).focusInDirection(TraversalDirection.down);
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.index % widget.itemsPerRow != 0) {
              FocusScope.of(context).focusInDirection(TraversalDirection.left);
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if ((widget.index + 1) % widget.itemsPerRow != 0 && 
                widget.index + 1 < widget.totalItems) {
              FocusScope.of(context).focusInDirection(TraversalDirection.right);
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            _handleFilmSelection();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: MouseRegion(
          onEnter: (final _) => setState(() => isHovered = true),
          onExit: (final _) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: _handleFilmSelection,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              transformAlignment: Alignment.center,
              transform: Matrix4.identity()..scale(scale),
              child: Material(
                elevation: elevation,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FastCachedImage(
                        url: widget.film.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.error_outline, size: 40),
                        ),
                        loadingBuilder: (final context, final progress) => Center(
                          child: CircularProgressIndicator(
                            value: progress.progressPercentage.value,
                          ),
                        ),
                      ),
                    ),
                    if (isFocused || isHovered)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
