import "package:unofficial_filman_client/notifiers/filman.dart";
import "package:unofficial_filman_client/screens/main.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:unofficial_filman_client/widgets/recaptcha.dart";
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
  late final GoogleReCaptchaController recaptchaV2Controller;

  void _submitForm() {
    setState(() {
      recaptchaV2Controller.show();
      isLoading = true;
    });
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

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (registerResponse.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Zarejestrowano pomyślnie!"),
        dismissDirection: DismissDirection.horizontal,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
      ));

      final loginResponse =
          await Provider.of<FilmanNotifier>(context, listen: false)
              .loginToFilman(loginController.text, passwordController.text);

      if (!mounted) return;
      if (loginResponse.success) {
        Provider.of<FilmanNotifier>(context, listen: false).saveUser(
          loginController.text,
          passwordController.text,
        );
        if (mounted) {
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
    recaptchaV2Controller = GoogleReCaptchaController()
      ..onToken((final String token) {
        _register(token);
      });
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
          child: Stack(
            children: [
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Center(
                      child: ListView(
                      shrinkWrap: true,
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
                                      "Tworząc konto zgadzasz się z treścią "),
                              TextSpan(
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          decoration: TextDecoration.underline),
                                  text: "regulaminu serwisu Filman.cc",
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final Uri uri = Uri.parse(
                                          "https://filman.cc/regulamin");
                                      if (!await launchUrl(uri,
                                          mode:
                                              LaunchMode.externalApplication)) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                "Nie można otworzyć linku w przeglądarce"),
                                            dismissDirection:
                                                DismissDirection.horizontal,
                                            behavior: SnackBarBehavior.floating,
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
                    )),
              GoogleReCaptcha(
                controller: recaptchaV2Controller,
                url: "https://filman.cc/rejestracja",
                siteKey: "6LcQs24iAAAAALFibpEQwpQZiyhOCn-zdc-eFout",
                languageCode: "pl",
              )
            ],
          )),
    );
  }
}
