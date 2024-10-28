import "package:flutter/material.dart";
import "package:flutter_inappwebview/flutter_inappwebview.dart";

class GoogleReCaptcha extends StatefulWidget {
  final String siteKey;
  final String url;
  final String languageCode;
  final GoogleReCaptchaController controller;

  const GoogleReCaptcha({
    super.key,
    required this.siteKey,
    required this.url,
    required this.controller,
    this.languageCode = "en",
  });

  @override
  State<GoogleReCaptcha> createState() => _GoogleReCaptchaState();
}

class _GoogleReCaptchaState extends State<GoogleReCaptcha> {
  String get htmlContent => '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://recaptcha.google.com/recaptcha/api.js?explicit&hl=${widget.languageCode}"></script>
        <script type="text/javascript">
          function onDataCallback(response) {
            window.flutter_inappwebview.callHandler('messageHandler', response);
            setTimeout(function () {
              document.getElementById('captcha').style.display = 'none';
            }, 1500);
          }
          function onCancel() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'cancel');
            document.getElementById('captcha').style.display = 'none';
          }
          function onDataExpiredCallback() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'expired');
          }
          function onDataErrorCallback() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'error');
          }
        </script>
      </head>
      <body>
        <div id="captcha" style="text-align: center; padding-top: 100px;">
          <div class="g-recaptcha" 
               style="display: inline-block; height: auto;" 
               data-sitekey="${widget.siteKey}" 
               data-callback="onDataCallback"
               data-expired-callback="onDataExpiredCallback"
               data-error-callback="onDataErrorCallback">
          </div>
        </div>
      </body>
    </html>
  ''';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(final BuildContext context) {
    if (!widget.controller.isVisible) return const SizedBox.shrink();
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.5),
        ),
        Center(
          child: InAppWebView(
            initialData: InAppWebViewInitialData(
              data: htmlContent,
              baseUrl: WebUri(widget.url),
            ),
            initialSettings: InAppWebViewSettings(transparentBackground: true),
            onWebViewCreated: (final InAppWebViewController controller) {
              controller.addJavaScriptHandler(
                handlerName: "messageHandler",
                callback: (final message) {
                  if (message[0] is String) {
                    widget.controller.callTokenCallback(message[0]);
                    widget.controller.hide();
                  } else {
                    widget.controller.hide();
                    return showDialog(
                      context: context,
                      builder: (final context) {
                        return AlertDialog(
                          title: const Text("Error"),
                          content: const Text(
                              "An error occurred while verifying the captcha."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.controller.hide();
                              },
                              child: const Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class GoogleReCaptchaController extends ChangeNotifier {
  bool _isVisible = false;
  void Function(String)? _onTokenCallback;

  bool get isVisible => _isVisible;

  void show() {
    _isVisible = true;
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  void onToken(final void Function(String) callback) {
    _onTokenCallback = callback;
  }

  void callTokenCallback(final String newToken) {
    if (_onTokenCallback != null) {
      _onTokenCallback!(newToken);
    }
  }
}
