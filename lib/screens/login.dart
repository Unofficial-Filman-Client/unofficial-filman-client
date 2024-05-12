import 'package:filman_flutter/screens/home.dart';
import 'package:filman_flutter/model.dart';
import 'package:filman_flutter/types/login_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController loginController;
  late final TextEditingController passwordController;

  void _submitForm() async {
    setState(() {
      isLoading = true;
    });

    final LoginResponse loginResponse =
        await Provider.of<FilmanModel>(context, listen: false)
            .loginToFilman(loginController.text, passwordController.text);

    setState(() {
      isLoading = false;
    });

    if (loginResponse.success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
        body: SafeArea(
      child: Padding(
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
                          child: Text('Zacznij logując się do filman.cc!',
                              style: TextStyle(
                                fontSize: 32,
                              )),
                        ),
                        const SizedBox(height: 23.0),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Nazwa użytkownika',
                            border: OutlineInputBorder(),
                          ),
                          controller: loginController,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16.0),
                        TextField(
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Hasło',
                            border: OutlineInputBorder(),
                          ),
                          controller: passwordController,
                          onSubmitted: (_) {
                            _submitForm();
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () {
                              _submitForm();
                            },
                            child: const Text('Zaloguj się'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ));
  }
}
