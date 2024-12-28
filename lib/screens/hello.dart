import "package:unofficial_filman_client/screens/login.dart";
import "package:unofficial_filman_client/screens/register.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/utils/updater.dart";

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  @override
  State<HelloScreen> createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  @override
  void initState() {
    super.initState();
    checkForUpdates();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Witaj w Filman.cc!",
                    style: TextStyle(fontSize: 32),
                  ),
                ),
                Text(
                    "Ta nieoficjalna aplikacja, stworzona przez entuzjaste programowania, wyświetla dane z Filman.cc i innych stron internetowych firm trzecich. Nie jesteśmy związani z Filman.cc ani z żadną inną stroną internetową, którą wyświetlamy. Traktuj tę aplikację jako narzędzie do przeglądania treści."),
              ],
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (final context) => const LoginScreen(),
                    )),
                child: const Text("Zaloguj się")),
          ),
          const SizedBox(
            height: 8,
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (final context) => const RegisterScreen(),
                    )),
                child: const Text("Stwórz konto")),
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    )));
  }
}
