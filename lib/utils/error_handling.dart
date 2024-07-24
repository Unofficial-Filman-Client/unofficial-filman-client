import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/hello.dart";
import "package:unofficial_filman_client/types/auth_response.dart";
import "package:unofficial_filman_client/types/exceptions.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

Widget buildErrorContent(
  final Object error,
  final BuildContext context,
  final void Function(AuthResponse response) onLogin,
) {
  if (error is LogOutException) {
    try {
      final user = Provider.of<FilmanNotifier>(context, listen: false).user;
      if (user != null) {
        Provider.of<FilmanNotifier>(context, listen: false)
            .loginToFilman(user.login, user.password)
            .then(onLogin);
        return const Center(
          child: Text("Logowanie ponowne..."),
        );
      } else {
        throw error;
      }
    } catch (e) {
      if (e is LogOutException) {
        WidgetsBinding.instance.addPostFrameCallback((final _) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nastąpiło wylogowanie!"),
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (final context) => const HelloScreen(),
            ),
          );
        });
        return const SizedBox.shrink();
      }
    }
  }

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Wystąpił błąd podczas ładowania strony ($error)"),
        FilledButton(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, "/", (final _) => false);
          },
          child: const Icon(Icons.refresh),
        ),
      ],
    ),
  );
}
