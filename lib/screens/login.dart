import "package:unofficial_filman_client/screens/main.dart";
import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController loginController;
  late final TextEditingController passwordController;

  void _login() async {
    setState(() {
      isLoading = true;
    });

    final loginResponse =
        await Provider.of<FilmanNotifier>(context, listen: false)
            .loginToFilman(loginController.text, passwordController.text);

    setState(() {
      isLoading = false;
    });

    if (loginResponse.success) {
      if (mounted) {
        Provider.of<FilmanNotifier>(context, listen: false).saveUser(
          loginController.text,
          passwordController.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (final context) => const MainScreen()),
        );
      }
    } else {
      for (final error in loginResponse.errors) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error),
            dismissDirection: DismissDirection.horizontal,
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
          ));
        }
      }
    }
  }

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loginController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    loginController.dispose();
    passwordController.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Zacznij logując się do filman.cc!",
                              style: TextStyle(
                                fontSize: 32,
                              )),
                        ),
                        const SizedBox(height: 23.0),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "Nazwa użytkownika",
                            border: OutlineInputBorder(),
                          ),
                          controller: loginController,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Hasło",
                            border: OutlineInputBorder(),
                          ),
                          controller: passwordController,
                          onSubmitted: (final _) {
                            _login();
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () {
                              _login();
                            },
                            child: const Text("Zaloguj się"),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
