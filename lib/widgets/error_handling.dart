import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/hello.dart";
import "package:unofficial_filman_client/types/auth_response.dart";
import "package:unofficial_filman_client/types/exceptions.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class ErrorHandling extends StatefulWidget {
  final Object error;
  final void Function(AuthResponse response) onLogin;

  const ErrorHandling({
    super.key,
    required this.error,
    required this.onLogin,
  });

  @override
  State<ErrorHandling> createState() => _ErrorHandlingState();
}

class _ErrorHandlingState extends State<ErrorHandling> {
  @override
  void initState() {
    super.initState();
    if (widget.error is LogOutException) {
      _handleLogOutException();
    }
  }

  void _logout() {
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
    setState(() {});
  }

  void _handleLogOutException() async {
    try {
      final filmanNotifier =
          Provider.of<FilmanNotifier>(context, listen: false);
      final needCaptcha = await filmanNotifier.checkIfCaptchaIsNeeded();
      if (needCaptcha) {
        _logout();
        return;
      }
      final user = filmanNotifier.user;
      if (user != null) {
        filmanNotifier
            .loginToFilman(user.login, user.password)
            .then(widget.onLogin);
      } else {
        throw widget.error;
      }
    } on LogOutException {
      _logout();
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (widget.error is LogOutException) {
      return const Center(
        child: Text("Logowanie ponowne..."),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Wystąpił błąd podczas ładowania strony (${widget.error})"),
          FilledButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, "/", (final _) => false);
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
