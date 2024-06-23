import 'package:filman_flutter/notifiers/filman.dart';
import 'package:filman_flutter/screens/hello.dart';
import 'package:filman_flutter/types/auth_response.dart';
import 'package:filman_flutter/types/exceptions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget buildErrorContent(
  Object error,
  BuildContext context,
  void onLogin(AuthResponse response),
) {
  if (error is LogOutException) {
    try {
      debugPrint('Trying to log in again');
      final user = Provider.of<FilmanNotifier>(context, listen: false).user;
      if (user != null) {
        Provider.of<FilmanNotifier>(context, listen: false)
            .loginToFilman(user.login, user.password)
            .then(onLogin);
        return const Center(
          child: Text('Logowanie ponowne...'),
        );
      } else {
        throw error;
      }
    } catch (e) {
      if (e is LogOutException) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nastąpiło wylogowanie!'),
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HelloScreen(),
            ),
          );
        });
        return const SizedBox.shrink();
      }
    }
  }

  return Center(
    child: Text("Wystąpił błąd podczas ładowania strony ($error)"),
  );
}
