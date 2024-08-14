import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/login.dart";
import "package:unofficial_filman_client/widgets/recaptcha.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:url_launcher/url_launcher.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final TextEditingController loginController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController repasswordController;

  RecaptchaV2Controller recaptchaV2Controller = RecaptchaV2Controller();

  void _submitForm() async {
    setState(() {
      isLoading = true;
    });

    recaptchaV2Controller.show();
  }

  void _register(final String recaptchatoken) async {
    final registerResponse =
        await Provider.of<FilmanNotifier>(context, listen: false)
            .createAccountOnFilmn(
                loginController.text,
                emailController.text,
                passwordController.text,
                repasswordController.text,
                recaptchatoken);

    setState(() {
      isLoading = false;
    });

    if (registerResponse.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Zarejestrowano pomyślnie!"),
          dismissDirection: DismissDirection.horizontal,
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (final context) => const LoginScreen()),
        );
      }
    } else {
      for (final error in registerResponse.errors) {
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
    emailController = TextEditingController();
    passwordController = TextEditingController();
    repasswordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    loginController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repasswordController.dispose();
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
                child: Stack(
              children: [
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Tworzysz nowe konto!",
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
                            decoration: const InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(),
                            ),
                            controller: emailController,
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
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Powtórz hasło",
                              border: OutlineInputBorder(),
                            ),
                            controller: repasswordController,
                            onSubmitted: (final _) {
                              _submitForm();
                            },
                          ),
                          const SizedBox(height: 16.0),
                          RichText(
                            text: TextSpan(
                              children: <TextSpan>[
                                TextSpan(
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                    text:
                                        "Tworzac konto zgadzasz się z treścią "),
                                TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            decoration:
                                                TextDecoration.underline),
                                    text: "regulaminu serwisu Filman.cc",
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        final Uri uri = Uri.parse(
                                            "https://filman.cc/regulamin");
                                        if (!await launchUrl(uri,
                                            mode: LaunchMode
                                                .externalApplication)) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Nie można otworzyć linku w przeglądarce"),
                                              dismissDirection:
                                                  DismissDirection.horizontal,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              showCloseIcon: true,
                                            ));
                                          }
                                        }
                                      }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: () {
                                _submitForm();
                              },
                              child: const Text("Zarejestruj się"),
                            ),
                          ),
                        ],
                      ),
                RecaptchaV2(
                  siteUrl: "https://filman.cc/rejestracja",
                  controller: recaptchaV2Controller,
                  onToken: (final token) {
                    _register(token);
                  },
                  onCanceled: (final value) {
                    setState(() {
                      isLoading = false;
                    });
                  },
                )
              ],
            )),
          ],
        ),
      ),
    );
  }
}
