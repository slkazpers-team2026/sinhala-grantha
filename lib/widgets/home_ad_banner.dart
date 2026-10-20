import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/ad_config_service.dart';
import 'web_ad/web_ad.dart';

class HomeAdBanner extends StatefulWidget {
  const HomeAdBanner({super.key});

  @override
  State<HomeAdBanner> createState() => _HomeAdBannerState();
}

class _HomeAdBannerState extends State<HomeAdBanner> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initBanner();
    }
  }

  void _initBanner() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Keep user sandboxed inside the banner boundary and prevent hijacking
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(AdConfigService.bannerAdUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfigService.isAdsEnabled) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      return const WebAdBanner(viewType: 'ad-banner-html');
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: const Color(0xFF334155), width: 1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                ),
              ),
            ),
          Positioned(
            top: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SPONSORED',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
