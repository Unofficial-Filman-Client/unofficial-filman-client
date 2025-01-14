// ignore_for_file: deprecated_member_use

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/category.dart";
import "package:unofficial_filman_client/screens/hello.dart";
import "package:unofficial_filman_client/screens/main/home.dart";
import "package:unofficial_filman_client/screens/main/offline.dart";
import "package:unofficial_filman_client/screens/main/watched.dart";
import "package:unofficial_filman_client/screens/settings.dart";
import "package:unofficial_filman_client/screens/main/search.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;
  int? focusedIndex;
  int? clickedIndex;
  final List<FocusNode> navigationFocusNodes = List.generate(7, (final _) => FocusNode());
  final List<FocusScopeNode> pageFocusScopes = List.generate(4, (final _) => FocusScopeNode());
  late FocusNode navigationBarFocusNode;
  late FocusNode keyboardListenerNode;
  bool _isContentHovered = false;

  @override
  void initState() {
    super.initState();
    navigationBarFocusNode = FocusNode();
    keyboardListenerNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (mounted) {
        _handlePageChange(0);
        navigationBarFocusNode.requestFocus();
        navigationFocusNodes[1].requestFocus();
        setState(() {
          focusedIndex = 1;
          clickedIndex = 1;
        });
      }
    });
  }

  void setContentHovered(final bool isHovered) {
    if (_isContentHovered != isHovered) {
      setState(() => _isContentHovered = isHovered);
    }
  }

  @override
  void dispose() {
    navigationBarFocusNode.dispose();
    keyboardListenerNode.dispose();
    for (var node in navigationFocusNodes) {
      node.dispose();
    }
    for (var scope in pageFocusScopes) {
      scope.dispose();
    }
    super.dispose();
  }

  void _handlePageChange(final int pageIndex) {
    setState(() {
      if (currentPageIndex < pageFocusScopes.length) {
        pageFocusScopes[currentPageIndex].unfocus();
      }
      currentPageIndex = pageIndex;
      
      if (pageIndex < pageFocusScopes.length) {
        Future.microtask(() => pageFocusScopes[pageIndex].requestFocus());
      }
    });
  }

  void _handleNavigation(final LogicalKeyboardKey key) {
    if (focusedIndex == null) return;

    int newIndex = focusedIndex!;
    if (key == LogicalKeyboardKey.arrowLeft) {
      newIndex = (focusedIndex! - 1).clamp(0, navigationFocusNodes.length - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      newIndex = (focusedIndex! + 1).clamp(0, navigationFocusNodes.length - 1);
    }

    if (newIndex != focusedIndex) {
      navigationFocusNodes[newIndex].requestFocus();
    }
  }

  void _returnToNavigation() {
    if (currentPageIndex < pageFocusScopes.length) {
      pageFocusScopes[currentPageIndex].unfocus();
    }
    navigationBarFocusNode.requestFocus();
    
    final int navIndex = switch (currentPageIndex) {
      0 => 1,
      1 => 3,
      2 => 4,
      3 => 0,
      _ => 1,
    };

    navigationFocusNodes[navIndex].requestFocus();
    setState(() {
      focusedIndex = navIndex;
      clickedIndex = navIndex;
    });
  }

  bool _handleKeyPress(final RawKeyEvent event) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp && _isContentHovered) {
      _returnToNavigation();
      return true;
    }
    return false;
  }

  @override
  Widget build(final BuildContext context) {
    return RawKeyboardListener(
      focusNode: keyboardListenerNode,
      onKey: _handleKeyPress,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildNavigationBar(),
              Expanded(
                child: IndexedStack(
                  index: currentPageIndex,
                  children: [
                    FocusScope(
                      node: pageFocusScopes[0],
                      child: HomePage(onHoverStateChanged: setContentHovered),
                    ),
                    FocusScope(
                      node: pageFocusScopes[1],
                      child: WatchedPage(onHoverStateChanged: setContentHovered),
                    ),
                    FocusScope(
                      node: pageFocusScopes[2],
                      child: OfflinePage(onHoverStateChanged: setContentHovered),
                    ),
                    FocusScope(
                      node: pageFocusScopes[3],
                      child: SearchScreen(
                        onHoverStateChanged: setContentHovered,
                        onNavigateToNavBar: _returnToNavigation,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Focus(
        focusNode: navigationBarFocusNode,
        onKey: (final node, final event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (currentPageIndex < pageFocusScopes.length) {
                pageFocusScopes[currentPageIndex].requestFocus();
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _handleNavigation(event.logicalKey);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Image.asset(
                "assets/images/logo.png",
                width: 40,
                height: 40,
              ),
            ),
            _buildNavItem(index: 0, label: "Szukaj", pageIndex: 3),
            const SizedBox(width: 8),
            Row(
              children: [
                _buildNavItem(index: 1, label: "Strona Główna", pageIndex: 0),
                _buildCategoryButton(),
                _buildNavItem(index: 3, label: "Oglądane", pageIndex: 1),
                _buildNavItem(index: 4, label: "Pobrane", pageIndex: 2),
              ],
            ),
            const Spacer(),
            _buildNavItem(
              index: 5,
              icon: Icons.settings,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (final _) => const SettingsScreen()),
              ),
            ),
            _buildNavItem(
              index: 6,
              icon: Icons.logout,
              onTap: () {
                Provider.of<FilmanNotifier>(context, listen: false).logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (final _) => const HelloScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required final int index,
    final String? label,
    final IconData? icon,
    final VoidCallback? onTap,
    final int? pageIndex,
  }) {
    final bool isSelected = pageIndex != null && currentPageIndex == pageIndex;
    final bool isFocused = focusedIndex == index;

    return Focus(
      focusNode: navigationFocusNodes[index],
      onFocusChange: (final hasFocus) {
        if (mounted) {
          setState(() => focusedIndex = hasFocus ? index : null);
        }
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.select)) {
          if (onTap != null) {
            onTap();
          } else if (pageIndex != null) {
            _handlePageChange(pageIndex);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else if (pageIndex != null) {
            _handlePageChange(pageIndex);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Transform.scale(
            scale: isFocused ? 1.1 : 1.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null || (label == "Szukaj" && icon == null))
                  Icon(
                    icon ?? Icons.search,
                    size: isFocused ? 26 : 24,
                    color: isSelected ? Colors.white : (isFocused ? Colors.white : Colors.grey),
                  ),
                if (label != null) ...[
                  if (icon != null || label == "Szukaj") const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                      fontSize: isFocused ? 15 : 14,
                      fontWeight: isSelected ? FontWeight.bold : (isFocused ? FontWeight.bold : FontWeight.normal),
                      color: isSelected ? Colors.white : (isFocused ? Colors.white : Colors.grey),
                    ),
                    duration: const Duration(milliseconds: 300),
                    child: Text(label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton() {
    final bool isFocused = focusedIndex == 2;

    return Focus(
      focusNode: navigationFocusNodes[2],
      onFocusChange: (final hasFocus) {
        setState(() => focusedIndex = hasFocus ? 2 : null);
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.select)) {
          _showCategoryOptions(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          setState(() => clickedIndex = 2);
          _showCategoryOptions(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: AnimatedScale(
            scale: isFocused || clickedIndex == 2 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              "Kategorie",
              style: TextStyle(
                fontSize: isFocused || clickedIndex == 2 ? 15 : 14,
                fontWeight: isFocused || clickedIndex == 2 ? FontWeight.bold : FontWeight.normal,
                color: isFocused || clickedIndex == 2 ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryOptions(final BuildContext context) {
    showDialog(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text("Wybierz typ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Filmy"),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (final _) => const CategoryScreen(forSeries: false)),
                );
              },
            ),
            ListTile(
              title: const Text("Seriale"),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (final _) => const CategoryScreen(forSeries: true)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}