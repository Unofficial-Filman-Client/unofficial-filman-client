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
import "package:unofficial_filman_client/utils/greeting.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/utils/updater.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;
  int? focusedIndex;

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 250,
              color: Colors.grey[900],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: "Strona Główna",
                    index: 0,
                  ),
                  _buildNavItem(
                    icon: Icons.watch_later,
                    label: "Oglądane",
                    index: 1,
                  ),
                  _buildNavItem(
                    icon: Icons.download,
                    label: "Pobrane",
                    index: 2,
                  ),
                  _buildNavItem(
                    icon: Icons.category,
                    label: "Filmy",
                    index: 3,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (final context) => const CategoryScreen(
                            forSeries: false,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.category,
                    label: "Seriale",
                    index: 4,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (final context) => const CategoryScreen(
                            forSeries: true,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.settings,
                    label: "Ustawienia",
                    index: 5,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (final context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                      icon: Icons.logout,
                      label: "Wyloguj się",
                      index: 6,
                      onTap: () {
                        Provider.of<FilmanNotifier>(context, listen: false)
                            .logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (final context) => const HelloScreen(),
                          ),
                        );
                      })
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
    required final IconData icon,
    required final String label,
    required final int index,
    final VoidCallback? onTap,
  }) {
    final bool isSelected = currentPageIndex == index;
    final bool isFocused = focusedIndex == index;

    return Focus(
      autofocus: index == 0,
      onFocusChange: (final hasFocus) {
        setState(() {
          focusedIndex = hasFocus ? index : null;
        });
      },
      onKeyEvent: (final FocusNode node, final KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            if (onTap != null) {
              onTap();
            } else {
              setState(() {
                currentPageIndex = index;
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
              currentPageIndex = index;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isFocused ? Colors.grey[800] : Colors.transparent,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: isSelected || isFocused ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  color: isSelected || isFocused ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
