import "package:flutter/material.dart";
import "package:webview_flutter/webview_flutter.dart";

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

  @override
  void initState() {
    controller = widget.controller;
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel("Captcha", onMessageReceived: (final token) {
        widget.onToken?.call(token.message);
        controller.hide();
        controller.unload();
        webViewController.clearCache();
        webViewController.reload();
      })
      ..addJavaScriptChannel(
        "Visible",
        onMessageReceived: (final visible) {
          debugPrint(visible.message);
          setState(() {
            if (bool.parse(visible.message) == true) controller.loaded();
          });
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (final String url) {
          webViewController.runJavaScript('''
            document.body.style.visibility="hidden";
            document.querySelector(".g-recaptcha")?.scrollIntoView(true);
            document.querySelector(".g-recaptcha").style.visibility = "visible"
            Visible.postMessage("true");
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
  void didUpdateWidget(final RecaptchaV2 oldWidget) {
    if (widget.controller != oldWidget.controller) {
      controller = widget.controller;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return controller.visible
        ? Stack(
            children: [
              Opacity(
                opacity: controller.loading ? 0.0 : 1.0,
                child: WebViewWidget(controller: webViewController),
              ),
              controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(),
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
                            controller.unload();
                            webViewController.clearCache();
                            webViewController.reload();
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

  bool _loading = true;
  bool get loading => _loading;

  void loaded() {
    _loading = false;
    if (!isDisposed) notifyListeners();
  }

  void unload() {
    _loading = true;
    if (!isDisposed) notifyListeners();
  }

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
  void addListener(final listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      super.addListener(listener);
    }
  }

  @override
  void removeListener(final listener) {
    _listeners.remove(listener);
    super.removeListener(listener);
  }
}
