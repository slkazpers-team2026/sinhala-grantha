import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/drm_service.dart';
import '../services/ad_config_service.dart';
import '../widgets/web_ad/web_ad.dart';

class EpubReaderScreen extends StatefulWidget {
  final String bookTitle;
  final String cachedFilePath;
  final String? epubUrl; // Optional: used for web when file path is not available

  const EpubReaderScreen({
    super.key,
    required this.bookTitle,
    required this.cachedFilePath,
    this.epubUrl,
  });

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  EpubController? _epubController;
  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 16.0;
  WebViewController? _bannerController;

  @override
  void initState() {
    super.initState();
    DrmService.secureScreen();
    if (!kIsWeb) {
      _initBannerController();
    }
    _initReader();
  }

  void _initBannerController() {
    _bannerController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('Banner ad loaded: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Banner ad error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(AdConfigService.readerBannerAdUrl));
  }

  Future<void> _initReader() async {
    try {
      if (kIsWeb) {
        // Web: Download book as bytes and load with openData
        final url = widget.epubUrl ?? widget.cachedFilePath;
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          _epubController = EpubController(
            document: EpubDocument.openData(response.bodyBytes),
          );
        } else {
          throw Exception('Failed to load EPUB from URL: ${response.statusCode}');
        }
      } else {
        // Mobile/Desktop: Read cached file as bytes
        final file = File(widget.cachedFilePath);
        if (!await file.exists()) {
          throw Exception('පොතෙහි ගොනුව සොයාගත නොහැක.');
        }

        final bytes = await file.readAsBytes();
        _epubController = EpubController(
          document: EpubDocument.openData(bytes),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('EpubReaderScreen Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'පොත විවෘත කිරීම අසාර්ථක විය: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
        title: Text(
          widget.bookTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_epubController != null)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.format_list_bulleted, color: Colors.indigoAccent),
                tooltip: 'පටුන (Table of Contents)',
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          PopupMenuButton<double>(
            icon: const Icon(Icons.format_size, color: Colors.white70),
            tooltip: 'අකුරු ප්‍රමාණය',
            onSelected: (val) {
              setState(() {
                _fontSize = val;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 14.0, child: Text('කුඩා (14pt)')),
              const PopupMenuItem(value: 16.0, child: Text('සාමාන්‍ය (16pt)')),
              const PopupMenuItem(value: 18.0, child: Text('විශාල (18pt)')),
              const PopupMenuItem(value: 22.0, child: Text('ඉතා විශාල (22pt)')),
            ],
          ),
        ],
      ),
      endDrawer: _epubController != null
          ? Drawer(
              backgroundColor: const Color(0xFF1E293B),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'පටුන',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Divider(color: Color(0xFF334155)),
                    Expanded(
                      child: EpubViewTableOfContents(
                        controller: _epubController!,
                        itemBuilder: (context, index, chapter, itemCount) {
                          return ListTile(
                            title: Text(
                              chapter.title?.trim() ?? 'පරිච්ඡේදය $index',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            onTap: () {
                              _epubController?.scrollTo(index: chapter.startIndex);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'පොත පූරණය වෙමින් පවතී...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : EpubView(
                  controller: _epubController!,
                  builders: EpubViewBuilders<DefaultBuilderOptions>(
                    options: DefaultBuilderOptions(
                      textStyle: TextStyle(
                        fontSize: _fontSize,
                        color: const Color(0xFFE2E8F0),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: _epubController != null
          ? SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chapter Info Bar
                  Container(
                    height: 48,
                    color: const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: EpubViewActualChapter(
                      controller: _epubController!,
                      builder: (chapterValue) => Text(
                        chapterValue?.chapter?.Title?.trim() ?? 'කියවමින්...',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Banner Ad (web): isolated iframe-based Adsterra slot
                  if (kIsWeb && AdConfigService.isAdsEnabled)
                    const WebAdBanner(viewType: 'ad-reader-html', height: 50),
                  // Banner Ad (only shown when ads are enabled and not on web)
                  if (!kIsWeb && AdConfigService.isAdsEnabled && _bannerController != null)
                    Container(
                      height: 70,
                      color: const Color(0xFF0F172A),
                      child: WebViewWidget(controller: _bannerController!),
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
