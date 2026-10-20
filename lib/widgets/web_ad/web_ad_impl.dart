import 'dart:html' as html;

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Web-only Adsterra banner.
///
/// The ad script is loaded inside a dedicated `<iframe>` pointing at
/// `ad_banner.html`. The iframe is registered as a platform view and mounted
/// through an [HtmlElementView], which keeps the ad markup fully isolated from
/// Flutter's own DOM and avoids the rendering jank of direct script injection.
class WebAdBanner extends StatelessWidget {
  const WebAdBanner({super.key, this.height = 110});

  static const String _viewType = 'adsterra-banner-view';
  static bool _isFactoryRegistered = false;

  final double height;

  static void _registerViewFactory() {
    if (_isFactoryRegistered) return;
    _isFactoryRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final html.IFrameElement iframe = html.IFrameElement()
        ..src = 'ad_banner.html'
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
      child: const HtmlElementView(viewType: _viewType),
    );
  }
}
