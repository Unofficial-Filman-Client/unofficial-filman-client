import "package:provider/provider.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/hello.dart";
import "package:unofficial_filman_client/types/auth_response.dart";
import "package:flutter/material.dart";
import "package:unofficial_filman_client/types/exceptions.dart";
import "package:unofficial_filman_client/widgets/recaptcha.dart";

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
  late final GoogleReCaptchaController recaptchaV2Controller;

  @override
  void initState() {
    if (widget.error is LogOutException) {
      recaptchaV2Controller = GoogleReCaptchaController()
        ..onToken((final token) async {
          final filmanNotifier =
              Provider.of<FilmanNotifier>(context, listen: false);
          final user = filmanNotifier.user;
          if (user == null) {
            return _logout();
          }
          final response = await filmanNotifier
              .loginToFilman(user.login, user.password, captchaToken: token);
          if (response.success) {
            return widget.onLogin(response);
          }
          return _logout();
        });
      recaptchaV2Controller.show();
    }
    super.initState();
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

  @override
  Widget build(final BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Wystąpił błąd podczas ładowania strony (${widget.error})",
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/", (final _) => false);
                },
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        if (widget.error is LogOutException)
          GoogleReCaptcha(
            controller: recaptchaV2Controller,
            url: "https://filman.cc/logowanie",
            siteKey: "6LcQs24iAAAAALFibpEQwpQZiyhOCn-zdc-eFout",
          )
      ],
    );
  }
}
