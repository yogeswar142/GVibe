// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
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
  static const String _viewTypeId = 'gvibe-globe-web-engine';
  static bool _registered = false;
  static html.IFrameElement? _currentIFrame;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewTypeId,
        (int viewId) {
          final isLight = widget.theme == 'light';
          final iframe = html.IFrameElement()
            ..src = 'assets/assets/globe/globe.html?theme=${widget.theme}'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = isLight ? '#F5FAF9' : '#000103';

          // Error fallback: try direct assets/globe/globe.html if nested assets not found
          iframe.onError.listen((_) {
            iframe.src = 'assets/globe/globe.html?theme=${widget.theme}';
          });

          _currentIFrame = iframe;
          return iframe;
        },
      );
      _registered = true;
    }

    // Listen to messages dispatched by globe.html via window.parent.postMessage
    html.window.addEventListener('message', _handleMessage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerCreated(this);
    });
  }

  @override
  void dispose() {
    html.window.removeEventListener('message', _handleMessage);
    super.dispose();
  }

  void _handleMessage(html.Event event) {
    if (event is! html.MessageEvent) return;
    final data = event.data;
    if (data is! Map) return;

    if (data['type'] == 'fromGlobe') {
      final handler = data['handlerName'];
      final payload = data['data'];

      switch (handler) {
        case 'onMapLoaded':
          widget.onMapLoaded();
          break;
        case 'onEdgeSwipeBack':
          widget.onEdgeSwipeBack();
          break;
        case 'onMarkerTapped':
          if (payload is Map) {
            widget.onMarkerTapped(Map<String, dynamic>.from(payload));
          }
          break;
        case 'onMapError':
          final msg = payload is Map ? payload['message']?.toString() : 'Error';
          widget.onMapError(msg ?? 'Web Map error');
          break;
      }
    }
  }

  void _postToGlobe(String action, [dynamic payload]) {
    _currentIFrame?.contentWindow?.postMessage(
      {
        'type': 'toGlobe',
        'action': action,
        'payload': payload,
      },
      '*',
    );
  }

  @override
  void flyToCampus() {
    _postToGlobe('flyToCampus');
  }

  @override
  void flyToUser(double lng, double lat, double zoom) {
    _postToGlobe('flyToUser', {'lng': lng, 'lat': lat, 'zoom': zoom});
  }

  @override
  void updateMarkers(List<Map<String, dynamic>> markers) {
    _postToGlobe('updateMarkers', markers);
  }

  @override
  void didUpdateWidget(covariant GlobePlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      setTheme(widget.theme);
    }
  }

  @override
  void setGlobeStyle(String styleUrl) {
    _postToGlobe('setGlobeStyle', {'styleUrl': styleUrl});
  }

  @override
  void setTheme(String theme) {
    _postToGlobe('setTheme', {'theme': theme});
    if (_currentIFrame != null) {
      _currentIFrame!.style.backgroundColor =
          theme == 'light' ? '#F5FAF9' : '#000103';
    }
  }

  @override
  void setPointerEvents(bool enable) {
    if (_currentIFrame != null) {
      _currentIFrame!.style.pointerEvents = enable ? 'auto' : 'none';
      _currentIFrame!.parent?.style.pointerEvents = enable ? 'auto' : 'none';
      _currentIFrame!
          .closest('flt-platform-view')
          ?.style
          .pointerEvents = enable ? 'auto' : 'none';
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: _viewTypeId);
  }
}
