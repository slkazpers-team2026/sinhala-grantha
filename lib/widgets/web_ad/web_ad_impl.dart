import 'dart:html' as html;

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web-only Adsterra banner.
///
/// The ad script is loaded inside a dedicated `<iframe>` pointing at one of the
/// static pages under `web/`. The iframe is registered as a platform view and
/// mounted through an [HtmlElementView], which keeps the ad markup fully
/// isolated from Flutter's own DOM and avoids the rendering jank of direct
/// script injection.
///
/// Pass the [viewType] matching the ad slot. Each view type is registered once
/// and maps to its own HTML page:
/// - `ad-banner-html` -> `ad_banner.html` (home banner)
/// - `ad-gate-html`   -> `ad_gate.html`   (interstitial screen)
/// - `ad-reader-html` -> `ad_reader.html` (reader bottom banner)
class WebAdBanner extends StatelessWidget {
  const WebAdBanner({super.key, required this.viewType, this.height = 110});

  /// Registered platform view types and the HTML page each one loads.
  static const Map<String, String> _viewSources = <String, String>{
    'ad-banner-html': 'ad_banner.html',
    'ad-gate-html': 'ad_gate.html',
    'ad-reader-html': 'ad_reader.html',
  };

  static final Set<String> _registeredViewTypes = <String>{};

  final String viewType;
  final double height;

  void _registerViewFactory() {
    if (_registeredViewTypes.contains(viewType)) return;

    final String? source = _viewSources[viewType];
    assert(source != null, 'Unknown web ad view type: $viewType');
    if (source == null) return;

    _registeredViewTypes.add(viewType);

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final html.IFrameElement iframe = html.IFrameElement()
        ..src = source
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden';
      iframe.setAttribute('scrolling', 'no');
      iframe.setAttribute('frameborder', '0');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    _registerViewFactory();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
