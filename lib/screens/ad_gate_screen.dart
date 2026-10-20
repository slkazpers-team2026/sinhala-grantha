import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/ad_config_service.dart';
import '../services/drm_service.dart';
import '../services/book_storage_service.dart';
import 'epub_reader_screen.dart';

class AdGateScreen extends StatefulWidget {
  final String bookTitle;
  final String bookId;
  final String epubUrl;

  const AdGateScreen({
    super.key,
    required this.bookTitle,
    required this.bookId,
    required this.epubUrl,
  });

  @override
  State<AdGateScreen> createState() => _AdGateScreenState();
}

class _AdGateScreenState extends State<AdGateScreen> {
  late int _secondsRemaining;
  late int _totalSeconds;
  Timer? _timer;
  WebViewController? _webViewController;
  File? _cachedFile;
  bool _isDownloadComplete = false;
  String _downloadStatus = 'පොත සුරක්ෂිතව සූදානම් කෙරේ...';

  @override
  void initState() {
    super.initState();
    // Enforce DRM screen security
    DrmService.secureScreen();

    _totalSeconds = AdConfigService.adCountdownSeconds > 0
        ? AdConfigService.adCountdownSeconds
        : 10;
    _secondsRemaining = _totalSeconds;

    if (!kIsWeb) {
      _initWebView();
    }
    _startCountdown();
    // Only precache on mobile/desktop (web uses in-memory download)
    if (!kIsWeb) {
      _precacheEpubInBackground();
    }
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..loadRequest(Uri.parse(AdConfigService.directAdUrl));
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _proceedToReader();
      }
    });
  }

  Future<void> _precacheEpubInBackground() async {
    try {
      final file = await BookStorageService.downloadAndCacheBook(
        bookId: widget.bookId,
        epubUrl: widget.epubUrl,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            final percent = ((received / total) * 100).toInt();
            setState(() {
              _downloadStatus = 'බාගත වෙමින් පවතී: $percent%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _cachedFile = file;
          _isDownloadComplete = true;
          _downloadStatus = 'පොත සූදානම්!';
        });
      }
    } catch (e) {
      debugPrint('AdGateScreen Precache error: $e');
      if (mounted) {
        setState(() {
          _downloadStatus = 'සම්බන්ධතාව පරීක්ෂා කෙරේ...';
        });
      }
    }
  }

  Future<void> _proceedToReader() async {
    if (!mounted) return;

    if (kIsWeb) {
      // Web: Pass URL directly for in-memory download
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EpubReaderScreen(
            bookTitle: widget.bookTitle,
            cachedFilePath: widget.epubUrl,
            epubUrl: widget.epubUrl,
          ),
        ),
      );
    } else {
      File file;
      if (_cachedFile != null) {
        file = _cachedFile!;
      } else {
        file = await BookStorageService.getInternalBookFile(widget.bookId);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EpubReaderScreen(
            bookTitle: widget.bookTitle,
            cachedFilePath: file.path,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (_totalSeconds - _secondsRemaining) / _totalSeconds;

    return PopScope(
      canPop: false, // Strict block on Android back navigation
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF1E293B),
            elevation: 4,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.bookTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.indigoAccent.withAlpha(120),
                        ),
                      ),
                      child: Text(
                        'පොත විවෘත වේ: ${_secondsRemaining}s',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigoAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.indigoAccent,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _downloadStatus,
                  style: TextStyle(
                    fontSize: 10,
                    color: _isDownloadComplete
                        ? Colors.greenAccent
                        : Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
        body: (!kIsWeb && _webViewController != null)
            ? WebViewWidget(controller: _webViewController!)
            : const Center(
                child: Text(
                  'දැන්වීම් පූරණය වෙමින්...',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
      ),
    );
  }
}
