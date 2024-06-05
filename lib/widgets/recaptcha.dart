// library flutter_recaptcha_v2_compat_compat; original from https://github.com/corgivn/flutter_recaptcha_v2

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaV2 extends StatefulWidget {
  final String siteUrl;
  final RecaptchaV2Controller controller;

  final ValueChanged<String>? onToken;
  final ValueChanged? onCanceled;

  const RecaptchaV2({
    super.key,
    required this.siteUrl,
    required this.controller,
    required this.onToken,
    required this.onCanceled,
  });

  @override
  State<StatefulWidget> createState() => _RecaptchaV2State();
}

class _RecaptchaV2State extends State<RecaptchaV2> {
  late RecaptchaV2Controller controller;
  late WebViewController webViewController;

  void onListen() {
    if (controller.visible) {
      webViewController.clearCache();
      webViewController.reload();
    }
    setState(() {
      controller.visible;
    });
  }

  @override
  void initState() {
    controller = widget.controller;
    controller.addListener(onListen);
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel("Captcha", onMessageReceived: (token) {
        widget.onToken?.call(token.message);
        controller.hide();
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          webViewController.runJavaScript('''
            document.body.style.visibility="hidden"
            document.querySelector(".g-recaptcha").scrollIntoView(true)
            document.querySelector(".g-recaptcha").style.visibility = "visible"
            interval = setInterval(()=>{
              let captcha = document.getElementsByName("g-recaptcha-response")[0].value
              if(captcha.length > 0) {
                Captcha.postMessage(captcha);
                clearInterval(interval);
              }
            },100)
          ''');
        },
      ))
      ..loadRequest(Uri.parse(widget.siteUrl));
  }

  @override
  void didUpdateWidget(RecaptchaV2 oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(onListen);
      controller = widget.controller;
      controller.removeListener(onListen);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.removeListener(onListen);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return controller.visible
        ? Stack(
            children: [
              WebViewWidget(controller: webViewController),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                          child: const Text("CANCEL RECAPTCHA"),
                          onPressed: () {
                            controller.hide();
                            widget.onCanceled?.call(null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Container();
  }
}

class RecaptchaV2Controller extends ChangeNotifier {
  bool isDisposed = false;
  List<VoidCallback> _listeners = [];

  bool _visible = false;
  bool get visible => _visible;

  void show() {
    _visible = true;
    if (!isDisposed) notifyListeners();
  }

  void hide() {
    _visible = false;
    if (!isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _listeners = [];
    isDisposed = true;
    super.dispose();
  }

  @override
  void addListener(listener) {
    _listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}
