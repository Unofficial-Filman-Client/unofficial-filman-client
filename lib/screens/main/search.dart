// ignore_for_file: deprecated_member_use

import "dart:ui";
import "package:fast_cached_network_image/fast_cached_network_image.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/film.dart";
import "package:unofficial_filman_client/types/search_results.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/settings.dart";
import "package:unofficial_filman_client/widgets/keyboard.dart";

class SearchScreen extends StatefulWidget {
  final Function(bool) onHoverStateChanged;
  final VoidCallback onNavigateToNavBar;

  const SearchScreen({
    super.key,
    required this.onHoverStateChanged,
    required this.onNavigateToNavBar,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late Future<SearchResults> lazySearch;
  late AnimationController _micScaleController;
  late AnimationController _searchScaleController;
  late AnimationController _clearScaleController;
  late final TextEditingController searchController;
  final FocusNode searchButtonFocus = FocusNode();
  final FocusScopeNode _focusScope = FocusScopeNode();
  final ScrollController _scrollController = ScrollController();
  final FocusNode micButtonFocus = FocusNode();
  final FocusNode _emptyStateFocusNode = FocusNode();
  final FocusNode clearButtonFocus = FocusNode();
  List<FocusNode> _resultFocusNodes = [];
  
  static const _gridSettings = {
    "columns": 6,
    "itemHeight": 180.0,
    "itemWidth": 116.0,
    "spacing": 12.0,
    "defaultScale": 1.0,
    "hoverScale": 1.1,
    "duration": Duration(milliseconds: 150),
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupFocusNodes();
    _requestInitialFocus();
  }

  void _initializeControllers() {
  searchController = TextEditingController();
  _micScaleController = AnimationController(
    duration: _gridSettings["duration"] as Duration,
    vsync: this,
    lowerBound: _gridSettings["defaultScale"] as double,
    upperBound: _gridSettings["hoverScale"] as double,
  );
  _searchScaleController = AnimationController(
    duration: _gridSettings["duration"] as Duration,
    vsync: this,
    lowerBound: _gridSettings["defaultScale"] as double,
    upperBound: _gridSettings["hoverScale"] as double,
  );
  _clearScaleController = AnimationController(
    duration: _gridSettings["duration"] as Duration,
    vsync: this,
    lowerBound: _gridSettings["defaultScale"] as double,
    upperBound: _gridSettings["hoverScale"] as double,
  );
}

  void _setupFocusNodes() {
  searchButtonFocus.addListener(_handleFocusChange);
  micButtonFocus.addListener(_handleFocusChange);
  clearButtonFocus.addListener(_handleFocusChange);
  _resultFocusNodes = List.generate(100, (final _) => FocusNode());
}

  void _requestInitialFocus() {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      searchButtonFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeFocusNodes();
    super.dispose();
  }

  void _disposeControllers() {
  searchController.dispose();
  _micScaleController.dispose();
  _searchScaleController.dispose();
  _clearScaleController.dispose();
  _scrollController.dispose();
}

  void _disposeFocusNodes() {
  searchButtonFocus.removeListener(_handleFocusChange);
  searchButtonFocus.dispose();
  micButtonFocus.dispose();
  clearButtonFocus.dispose();
  _focusScope.dispose();
  _emptyStateFocusNode.dispose();
  for (var node in _resultFocusNodes) {
    node.dispose();
  }
}

  void _handleFocusChange() {
    widget.onHoverStateChanged(searchButtonFocus.hasFocus || micButtonFocus.hasFocus);
  }

  void _clearSearch() {
  setState(() {
    searchController.clear();
    // No need to set lazySearch since the UI already handles empty searchController state
  });
}

  Future<void> _showSearchDialog() async {
    final useCustomKeyboard = Provider.of<SettingsNotifier>(context, listen: false).useCustomKeyboard;
    final result = await showDialog<String>(
      context: context,
      builder: (final _) => _SearchDialog(
        controller: searchController,
        useCustomKeyboard: useCustomKeyboard,
      ),
    );

    if (result?.isNotEmpty ?? false) {
      _handleSearch(result!);
    }
  }

  void _handleSearch(final String value) {
    if (value.length > 1) {
      setState(() {
        lazySearch = Provider.of<FilmanNotifier>(context, listen: false).searchInFilman(value);
      });
    }
  }

  void _showVoiceSearchDialog() {
    showDialog(
      context: context,
      builder: (final _) => AlertDialog(
        title: const Text("Informacja"),
        content: const Text("Wyszukiwanie głosowe wkrótce"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _scrollToVisible(final int index, final int totalItems) {
    if (!_scrollController.hasClients) return;
    final itemContext = _resultFocusNodes[index].context;
    if (itemContext != null) {
      Scrollable.ensureVisible(
        itemContext,
        alignment: 0.3,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  Widget _buildMicButton() {
    return Focus(
      focusNode: micButtonFocus,
      onFocusChange: (final hasFocus) {
        hasFocus ? _micScaleController.forward() : _micScaleController.reverse();
        widget.onHoverStateChanged(hasFocus);
      },
      onKey: (final _, final event) => _handleMicButtonKey(event),
      child: ScaleTransition(
        scale: _micScaleController,
        child: GestureDetector(
          onTap: _showVoiceSearchDialog,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(20, 0, 0, 0),
              border: Border.all(
                color: micButtonFocus.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Icon(
              Icons.mic,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
  return MouseRegion(
    onEnter: (final _) => _clearScaleController.forward(),
    onExit: (final _) => _clearScaleController.reverse(),
    child: Focus(
      focusNode: clearButtonFocus,
      onFocusChange: (final hasFocus) {
        widget.onHoverStateChanged(hasFocus);
        if (hasFocus) {
          _clearScaleController.forward();
        } else {
          _clearScaleController.reverse();
        }
      },
      onKey: (final _, final event) {
        if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowUp:
            widget.onNavigateToNavBar();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowLeft:
            searchButtonFocus.requestFocus();
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowDown:
            if (searchController.text.isNotEmpty) {
              _resultFocusNodes[0].requestFocus();
            }
            return KeyEventResult.handled;
          case LogicalKeyboardKey.select:
          case LogicalKeyboardKey.enter:
            _clearSearch();
            return KeyEventResult.handled;
          default:
            return KeyEventResult.ignored;
        }
      },
      child: ScaleTransition(
        scale: _clearScaleController,
        child: GestureDetector(
          onTap: _clearSearch,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(20, 0, 0, 0),
              border: Border.all(
                color: clearButtonFocus.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
      ),
    ),
  );
}

  KeyEventResult _handleMicButtonKey(final RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        widget.onNavigateToNavBar();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        searchButtonFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (searchController.text.isNotEmpty) {
          _resultFocusNodes[0].requestFocus();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _showVoiceSearchDialog();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Widget _buildSearchButton() {
    return Focus(
      focusNode: searchButtonFocus,
      onFocusChange: (final hasFocus) {
        hasFocus ? _searchScaleController.forward() : _searchScaleController.reverse();
        widget.onHoverStateChanged(hasFocus);
      },
      onKey: (final _, final event) => _handleSearchButtonKey(event),
      child: ScaleTransition(
        scale: _searchScaleController,
        child: GestureDetector(
          onTap: _showSearchDialog,
          child: Container(
            height: 48,
            width: MediaQuery.of(context).size.width * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color.fromARGB(20, 0, 0, 0),
              border: Border.all(
                color: searchButtonFocus.hasFocus
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    searchController.text.isNotEmpty ? searchController.text : "Wyszukaj",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleSearchButtonKey(final RawKeyEvent event) {
  if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

  switch (event.logicalKey) {
    case LogicalKeyboardKey.arrowUp:
      widget.onNavigateToNavBar();
      return KeyEventResult.handled;
    case LogicalKeyboardKey.arrowLeft:
      micButtonFocus.requestFocus();
      return KeyEventResult.handled;
    case LogicalKeyboardKey.arrowRight:
      if (searchController.text.isNotEmpty) {
        clearButtonFocus.requestFocus();
      }
      return KeyEventResult.handled;
    case LogicalKeyboardKey.arrowDown:
      if (searchController.text.isNotEmpty) {
        _resultFocusNodes[0].requestFocus();
      }
      return KeyEventResult.handled;
    case LogicalKeyboardKey.select:
    case LogicalKeyboardKey.enter:
      _showSearchDialog();
      return KeyEventResult.handled;
    default:
      return KeyEventResult.ignored;
  }
}

  Widget _buildSearchResults(final SearchResults? results) {
    if (results?.isNotEmpty() != true) {
      return Focus(
        focusNode: _emptyStateFocusNode,
        onFocusChange: (final _) => widget.onHoverStateChanged(false),
        child: const Center(child: Text("Brak wyników")),
      );
    }

    final films = results!.getFilms();
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _gridSettings["columns"] as int,
        childAspectRatio: (_gridSettings["itemWidth"] as double) / (_gridSettings["itemHeight"] as double),
        crossAxisSpacing: _gridSettings["spacing"] as double,
        mainAxisSpacing: _gridSettings["spacing"] as double,
      ),
      padding: const EdgeInsets.all(16),
      itemCount: films.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (final _, final index) => _buildGridItem(films[index], index, films.length),
    );
  }

  Widget _buildGridItem(final dynamic film, final int index, final int totalItems) {
    return Center(
      child: Focus(
        focusNode: _resultFocusNodes[index],
        onKey: (final _, final event) => _handleGridItemKey(event, index, totalItems, film),
        onFocusChange: (final hasFocus) {
          setState(() {});
          widget.onHoverStateChanged(false);
        },
        child: AnimatedScale(
          scale: _resultFocusNodes[index].hasFocus 
              ? _gridSettings["hoverScale"] as double 
              : _gridSettings["defaultScale"] as double,
          duration: _gridSettings["duration"] as Duration,
          child: AnimatedContainer(
            duration: _gridSettings["duration"] as Duration,
            decoration: BoxDecoration(
              border: Border.all(
                color: _resultFocusNodes[index].hasFocus ? Colors.blue : Colors.transparent,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () => _navigateToFilm(film),
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: _resultFocusNodes[index].hasFocus ? 8 : 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FastCachedImage(
                  url: film.imageUrl,
                  fit: BoxFit.cover,
                  height: _gridSettings["itemHeight"] as double,
                  width: _gridSettings["itemWidth"] as double,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToFilm(final dynamic film) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (final _) => FilmScreen(
          url: film.link,
          title: film.title,
          image: film.imageUrl,
        ),
      ),
    );
  }

  KeyEventResult _handleGridItemKey(final RawKeyEvent event, final int index, final int totalItems, final dynamic film) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    final int columns = _gridSettings["columns"] as int;
    
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (index + columns < totalItems) {
          _resultFocusNodes[index + columns].requestFocus();
          _scrollToVisible(index + columns, totalItems);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (index < columns) {
          searchButtonFocus.requestFocus();
        } else if (index - columns >= 0) {
          _resultFocusNodes[index - columns].requestFocus();
          _scrollToVisible(index - columns, totalItems);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (index % columns != 0) {
          _resultFocusNodes[index - 1].requestFocus();
        } else if (index == 0) {
          micButtonFocus.requestFocus();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if ((index + 1) % columns != 0 && index + 1 < totalItems) {
          _resultFocusNodes[index + 1].requestFocus();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        _navigateToFilm(film);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(final BuildContext context) {
    return FocusScope(
      node: _focusScope,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMicButton(),
                const SizedBox(width: 24),
                _buildSearchButton(),
                if (searchController.text.isNotEmpty) ...[
                  const SizedBox(width: 24),
                  _buildClearButton(),
                ],
              ],
            ),
          ),
          Expanded(
            child: MouseRegion(
              onEnter: (final _) => widget.onHoverStateChanged(false),
              onExit: (final _) => widget.onHoverStateChanged(false),
              child: searchController.text.isNotEmpty
                ? FutureBuilder<SearchResults>(
                    future: lazySearch,
                    builder: (final context, final snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text("Wystąpił błąd podczas wyszukiwania, ${snapshot.error}"),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.done) {
                        return _buildSearchResults(snapshot.data);
                      }
                      return const Center(child: Text("Brak wyników"));
                    },
                  )
                : const Center(child: Text("Kliknij przycisk wyszukiwania aby rozpocząć")),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final TextEditingController controller;
  final bool useCustomKeyboard;

  const _SearchDialog({
    required this.controller,
    required this.useCustomKeyboard,
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final FocusNode _searchFocus = FocusNode();
  final FocusNode _searchBarFocus = FocusNode();
  final GlobalKey<CustomKeyboardState> _keyboardKey = GlobalKey<CustomKeyboardState>();
  bool isKeyboardVisible = true;
  SearchResults? previewResults;
  Key _previewKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeFocus();
  }

  void _initializeFocus() {
    if (widget.useCustomKeyboard) {
      _searchBarFocus.requestFocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _keyboardKey.currentState != null) {
          _keyboardKey.currentState?.focusFirstKey();
        }
      });
    } else {
      _searchFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchBarFocus.dispose();
    super.dispose();
  }

  void _handleSubmit([final String? value]) {
    Navigator.of(context).pop(value ?? widget.controller.text);
  }

  Future<void> _handleChange(final String value) async {
    if (value.length > 1) {
      final results = await Provider.of<FilmanNotifier>(context, listen: false)
          .searchInFilman(value);
      if (mounted) {
        setState(() {
          previewResults = results;
          _previewKey = UniqueKey();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          previewResults = null;
          _previewKey = UniqueKey();
        });
      }
    }
  }

  Widget _buildPreviewResults() {
    if (previewResults?.isNotEmpty() != true) return const SizedBox.shrink();

    final previewFilms = previewResults!.getFilms().take(3).toList();
    return KeyedSubtree(
      key: _previewKey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: previewFilms.map((final film) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FastCachedImage(
              url: film.imageUrl,
              fit: BoxFit.cover,
              height: 120,
              width: 80,
              fadeInDuration: const Duration(milliseconds: 200),
              errorBuilder: (final context, final error, final stackTrace) => Container(
                height: 120,
                width: 80,
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.white),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final hasResults = previewResults?.isNotEmpty() == true;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.only(
                bottom: hasResults 
                  ? MediaQuery.of(context).size.height * 0.35 
                  : MediaQuery.of(context).size.height * 0.2
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Szukaj:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF303030),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Focus(
                      focusNode: _searchBarFocus,
                      onKey: (final _, final event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.arrowDown &&
                            _keyboardKey.currentState != null) {
                          _keyboardKey.currentState?.focusFirstKey();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: SearchBar(
                        controller: widget.controller,
                        focusNode: _searchFocus,
                        hintText: "Wyszukaj",
                        hintStyle: MaterialStateProperty.all(
                          TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                        textStyle: MaterialStateProperty.all(
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        backgroundColor: MaterialStateProperty.all(Colors.transparent),
                        elevation: MaterialStateProperty.all(0),
                        textInputAction: TextInputAction.search,
                        keyboardType: widget.useCustomKeyboard ? TextInputType.none : TextInputType.text,
                        onSubmitted: _handleSubmit,
                        onChanged: _handleChange,
                        padding: const MaterialStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        leading: Icon(
                          Icons.search, 
                          size: 18,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPreviewResults(),
                ],
              ),
            ),
          ),
          if (widget.useCustomKeyboard && isKeyboardVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomKeyboard(
                key: _keyboardKey,
                controller: widget.controller,
                onChanged: _handleChange,
                onSubmit: _handleSubmit,
                onUpFromFirstRow: () => _searchBarFocus.requestFocus(),
                autoFocus: false,
              ),
            ),
        ],
      ),
    );
  }
}
