import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'globe_controller.dart';

class GlobePlatformView extends StatefulWidget {
  final ValueChanged<GlobeViewController> onControllerCreated;
  final VoidCallback onMapLoaded;
  final VoidCallback onEdgeSwipeBack;
  final ValueChanged<Map<String, dynamic>> onMarkerTapped;
  final ValueChanged<String> onMapError;

  final String theme;

  const GlobePlatformView({
    super.key,
    required this.onControllerCreated,
    required this.onMapLoaded,
    required this.onEdgeSwipeBack,
    required this.onMarkerTapped,
    required this.onMapError,
    this.theme = 'dark',
  });

  @override
  State<GlobePlatformView> createState() => _GlobePlatformViewState();
}

class _GlobePlatformViewState extends State<GlobePlatformView>
    implements GlobeViewController {
  InAppWebViewController? _controller;
  final InAppWebViewKeepAlive _keepAlive = InAppWebViewKeepAlive();

  @override
  void didUpdateWidget(covariant GlobePlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      setTheme(widget.theme);
    }
  }

  @override
  void flyToCampus() {
    _controller?.evaluateJavascript(source: 'window.flyToCampus();');
  }

  @override
  void flyToUser(double lng, double lat, double zoom) {
    _controller?.evaluateJavascript(
      source: 'window.flyToUser($lng, $lat, $zoom);',
    );
  }

  @override
  void updateMarkers(List<Map<String, dynamic>> markers) {
    _controller?.evaluateJavascript(
      source: 'window.updateMarkers(${jsonEncode(markers)});',
    );
  }

  @override
  void setGlobeStyle(String styleUrl) {
    _controller?.evaluateJavascript(
      source: 'window.setGlobeStyle("$styleUrl");',
    );
  }

  @override
  void setTheme(String theme) {
    _controller?.evaluateJavascript(
      source: 'if (typeof window.setTheme === "function") window.setTheme("$theme");',
    );
  }

  @override
  void setPointerEvents(bool enable) {
    // In mobile WebView, Flutter automatically handles hit testing over InAppWebView.
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      keepAlive: _keepAlive,
      initialFile: 'assets/globe/globe.html',
      initialSettings: InAppWebViewSettings(
        isInspectable: kDebugMode,
        supportZoom: false,
        transparentBackground: true,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        cacheEnabled: true,
      ),
      onWebViewCreated: (c) {
        _controller = c;
        widget.onControllerCreated(this);

        c.addJavaScriptHandler(
          handlerName: 'onMapLoaded',
          callback: (_) => widget.onMapLoaded(),
        );
        c.addJavaScriptHandler(
          handlerName: 'onEdgeSwipeBack',
          callback: (_) => widget.onEdgeSwipeBack(),
        );
        c.addJavaScriptHandler(
          handlerName: 'onMarkerTapped',
          callback: (args) {
            if (args.isNotEmpty && args[0] is Map) {
              widget.onMarkerTapped(Map<String, dynamic>.from(args[0] as Map));
            }
          },
        );
        c.addJavaScriptHandler(
          handlerName: 'onMapError',
          callback: (args) {
            if (args.isNotEmpty && args[0] is Map) {
              widget.onMapError(args[0]['message']?.toString() ?? 'Error');
            }
          },
        );
      },
    );
  }
}
