import 'package:flutter/material.dart';

/// Mobile stub for the web ad banner.
///
/// The real implementation lives in `web_ad_impl.dart` and is only used on
/// platforms that have `dart:html` available. On mobile this widget collapses
/// to nothing so the rest of the layout is unaffected.
class WebAdBanner extends StatelessWidget {
  const WebAdBanner({super.key, required this.viewType, this.height = 110});

  /// Ad slot identifier, e.g. `ad-banner-html`, `ad-gate-html` or
  /// `ad-reader-html`. Ignored on mobile.
  final String viewType;

  final double height;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
