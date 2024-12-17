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
import "package:unofficial_filman_client/widgets/search.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;
  int? focusedIndex;
  int? clickedIndex;
  final List<FocusNode> navigationFocusNodes = [];
  final List<FocusScopeNode> pageFocusScopes = [];
  late FocusNode navigationBarFocusNode;
  late FocusNode keyboardListenerNode;
  bool _isContentHovered = false;
  
  @override
  void initState() {
    super.initState();
    navigationBarFocusNode = FocusNode();
    keyboardListenerNode = FocusNode();
    for (int i = 0; i < 7; i++) {
      navigationFocusNodes.add(FocusNode());
    }
    for (int i = 0; i < 3; i++) {
      pageFocusScopes.add(FocusScopeNode());
    }

    Future.microtask(() {
      if (mounted) {
        navigationBarFocusNode.requestFocus();
        navigationFocusNodes[0].requestFocus();
      }
    });
  }

  void setContentHovered(final bool isHovered) {
    if (_isContentHovered != isHovered) {
      setState(() {
        _isContentHovered = isHovered;
      });
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
      clickedIndex = null;
      focusedIndex = null;
      if (pageIndex < pageFocusScopes.length) {
        Future.microtask(() {
          pageFocusScopes[pageIndex].requestFocus();
        });
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
    int navIndex;
    switch (currentPageIndex) {
      case 0:
        navIndex = 1;
        break;
      case 1:
        navIndex = 3;
        break;
      case 2:
        navIndex = 4;
        break;
      default:
        navIndex = 1;
    }
    navigationFocusNodes[navIndex].requestFocus();
  }

  bool _handleKeyPress(final RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp && _isContentHovered) {
        _returnToNavigation();
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(final BuildContext context) {
    return RawKeyboardListener(
      focusNode: keyboardListenerNode,
      onKey: (final event) {
        _handleKeyPress(event);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Image.asset(
                          "assets/images/logo.png",
                          width: 40,
                          height: 40,
                        ),
                      ),
                      _buildSearchButton(),
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (final context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildNavItem(
                        index: 6,
                        icon: Icons.logout,
                        onTap: () {
                          Provider.of<FilmanNotifier>(context, listen: false).logout();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (final context) => const HelloScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
                  ],
                ),
              ),
            ],
          ),
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
          setState(() {
            focusedIndex = hasFocus ? index : null;
          });
        }
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            if (onTap != null) {
              onTap();
            } else if (pageIndex != null) {
              _handlePageChange(pageIndex);
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            clickedIndex = index;
          });
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Transform.scale(
            scale: isFocused || clickedIndex == index ? 1.1 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: isFocused || clickedIndex == index ? 26 : 24,
                    color: isSelected || isFocused || clickedIndex == index
                        ? Colors.white
                        : Colors.grey,
                  ),
                if (label != null)
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                      fontSize: isFocused || clickedIndex == index ? 15 : 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected || isFocused || clickedIndex == index
                          ? Colors.white
                          : Colors.grey,
                    ),
                    duration: const Duration(milliseconds: 300),
                    child: Text(label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    final bool isFocused = focusedIndex == 0;

    return Focus(
      focusNode: navigationFocusNodes[0],
      onFocusChange: (final hasFocus) {
        setState(() {
          focusedIndex = hasFocus ? 0 : null;
        });
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            _showBottomSheet();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            clickedIndex = 0;
          });
          _showBottomSheet();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedScale(
            scale: isFocused || clickedIndex == 0 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 26,
                  color: isFocused || clickedIndex == 0 ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isFocused || clickedIndex == 0 ? Colors.white : Colors.grey,
                  ),
                  child: const Text("Szukaj"),
                ),
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
        setState(() {
          focusedIndex = hasFocus ? 2 : null;
        });
      },
      onKey: (final node, final event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            _showCategoryOptions(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            clickedIndex = 2;
          });
          _showCategoryOptions(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedScale(
            scale: isFocused || clickedIndex == 2 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              "Kategorie",
              style: TextStyle(
                fontSize: isFocused || clickedIndex == 2 ? 15 : 14,
                fontWeight: FontWeight.bold,
                color: isFocused || clickedIndex == 2
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (final context) => const SearchModal(),
    );
  }
  void _showCategoryOptions(final BuildContext context) {
    showDialog(
      context: context,
      builder: (final BuildContext context) {
        return AlertDialog(
          title: const Text("Wybierz typ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Filmy"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (final context) => const CategoryScreen(forSeries: false),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text("Seriale"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (final context) => const CategoryScreen(forSeries: true),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
