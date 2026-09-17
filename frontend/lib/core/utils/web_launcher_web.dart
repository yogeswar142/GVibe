import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(JSString url, JSString target);

/// Direct browser window open implementation for Flutter Web using modern JS interop.
/// Bypasses Flutter's plugin channel to guarantee instant redirection without MissingPluginException.
void openInWebBrowser(String url) {
  _windowOpen(url.toJS, '_blank'.toJS);
}
