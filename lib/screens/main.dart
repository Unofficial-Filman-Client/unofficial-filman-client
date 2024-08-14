import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/hello.dart";
import "package:unofficial_filman_client/screens/main/home.dart";
import "package:unofficial_filman_client/screens/main/offline.dart";
import "package:unofficial_filman_client/screens/main/watched.dart";
import "package:unofficial_filman_client/screens/settings.dart";
import "package:unofficial_filman_client/utils/greeting.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  AppBar _buildAppBar(final BuildContext context,
      {final bool showProgress = false}) {
    return AppBar(
      title: Text(createTimeBasedGreeting(
          Provider.of<FilmanNotifier>(context).user?.login ?? "")),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (final context) => const SettingsScreen(),
              ),
            );
          },
          icon: const Icon(Icons.settings),
        ),
        IconButton(
          onPressed: () {
            Provider.of<FilmanNotifier>(context, listen: false).logout();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (final context) => const HelloScreen(),
              ),
            );
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      automaticallyImplyLeading: false,
      bottom: showProgress
          ? const PreferredSize(
              preferredSize: Size.fromHeight(4),
              child: LinearProgressIndicator(),
            )
          : null,
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (final int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: "Strona Główna",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.watch_later),
            icon: Icon(Icons.watch_later_outlined),
            label: "Oglądane",
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.download),
            icon: Icon(Icons.download_outlined),
            label: "Pobrane",
          ),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: const [
          HomePage(),
          WatchedPage(),
          OfflinePage(),
        ],
      ),
    );
  }
}
