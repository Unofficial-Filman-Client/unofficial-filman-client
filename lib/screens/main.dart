import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:unofficial_filman_client/notifiers/filman.dart';
import 'package:unofficial_filman_client/screens/category.dart';
import 'package:unofficial_filman_client/screens/hello.dart';
import 'package:unofficial_filman_client/screens/main/home.dart';
import 'package:unofficial_filman_client/screens/main/offline.dart';
import 'package:unofficial_filman_client/screens/main/watched.dart';
import 'package:unofficial_filman_client/screens/settings.dart';
import 'package:unofficial_filman_client/widgets/search.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;
  int? focusedIndex;
  int? clickedIndex;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Image.asset(
                      'assets/images/flutter_logo.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  _buildSearchButton(),
                  SizedBox(width: 8),
                  Row(
                    children: [
                      _buildNavItem(index: 0, label: "Strona Główna"),
                      _buildCategoryButton(),
                      _buildNavItem(index: 1, label: "Oglądane"),
                      _buildNavItem(index: 2, label: "Pobrane"),
                    ],
                  ),
                  Spacer(),
                  _buildNavItem(
                    index: 5,
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    index: 6,
                    icon: Icons.logout,
                    onTap: () {
                      Provider.of<FilmanNotifier>(context, listen: false)
                          .logout();
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
            Expanded(
              child: IndexedStack(
                index: currentPageIndex,
                children: const [
                  HomePage(),
                  WatchedPage(),
                  OfflinePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    final int? index,
    final String? label,
    final IconData? icon,
    final VoidCallback? onTap,
  }) {
    final bool isSelected = currentPageIndex == index;
    final bool isFocused = focusedIndex == index;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          focusedIndex = hasFocus ? index : null;
        });
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            if (onTap != null) {
              onTap();
            } else {
              setState(() {
                currentPageIndex = index!;
                clickedIndex = index;
              });
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap();
          } else {
            setState(() {
              currentPageIndex = index!;
              clickedIndex = null;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Transform.scale(
            scale: isFocused || clickedIndex == index ? 1.1 : 1.0,
            child: Column(
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

  void _showCategoryOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wybierz typ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Filmy'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(forSeries: false),
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Seriale'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(forSeries: true),
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

  Widget _buildSearchButton() {
    final bool isFocused = focusedIndex == 200;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          focusedIndex = hasFocus ? 200 : null;
        });
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            _showBottomSheet();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _showBottomSheet,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedScale(
            scale: isFocused || clickedIndex == 200 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 26,
                  color: isFocused || clickedIndex == 200 ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isFocused || clickedIndex == 200 ? Colors.white : Colors.grey,
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

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SearchModal(),
    );
  }

  Widget _buildCategoryButton() {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          focusedIndex = hasFocus ? 3 : null;
        });
      },
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
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
            clickedIndex = 3;
          });
          _showCategoryOptions(context);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedScale(
            scale: focusedIndex == 3 || clickedIndex == 3 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: focusedIndex == 3 || clickedIndex == 3 ? 15 : 14,
                fontWeight: FontWeight.bold,
                color: focusedIndex == 3 || clickedIndex == 3
                    ? Colors.white
                    : Colors.grey,
              ),
              child: const Text("Kategorie"),
            ),
          ),
        ),
      ),
    );
  }
}
