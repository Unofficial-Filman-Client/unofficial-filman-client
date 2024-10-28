import "package:unofficial_filman_client/types/auth_response.dart";
import "package:flutter/material.dart";

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
  }

  // void _logout() {
  //   WidgetsBinding.instance.addPostFrameCallback((final _) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Nastąpiło wylogowanie!"),
  //         dismissDirection: DismissDirection.horizontal,
  //         behavior: SnackBarBehavior.floating,
  //         showCloseIcon: true,
  //       ),
  //     );
  //     Navigator.of(context).pushReplacement(
  //       MaterialPageRoute(
  //         builder: (final context) => const HelloScreen(),
  //       ),
  //     );
  //   });
  //   setState(() {});
  // }

  @override
  Widget build(final BuildContext context) {
    return Center(
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
    );
  }
}
