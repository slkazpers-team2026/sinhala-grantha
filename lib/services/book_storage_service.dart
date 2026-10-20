import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class BookStorageService {
  static final Dio _dio = Dio();

  /// Returns the internal app cache file path for a book EPUB.
  /// Files are saved exclusively inside getApplicationSupportDirectory,
  /// strictly blocking public gallery/Downloads indexing.
  /// Only available on mobile/desktop platforms.
  static Future<File> getInternalBookFile(String bookId) async {
    if (kIsWeb) {
      throw UnsupportedError('File storage is not available on web platform');
    }
    final dir = await getApplicationSupportDirectory();
    final booksDir = Directory('${dir.path}/books_drm_cache');
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return File('${booksDir.path}/$bookId.epub');
  }

  /// Checks if the book is already cached locally.
  /// Only available on mobile/desktop platforms.
  static Future<bool> isBookCached(String bookId) async {
    if (kIsWeb) {
      return false;
    }
    final file = await getInternalBookFile(bookId);
    return await file.exists();
  }

  /// Downloads and caches the EPUB securely in the internal sandbox.
  /// Provides onProgress callback for tracking download progress.
  /// Only available on mobile/desktop platforms.
  static Future<File> downloadAndCacheBook({
    required String bookId,
    required String epubUrl,
    Function(int received, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('File storage is not available on web platform');
    }
    final targetFile = await getInternalBookFile(bookId);

    if (await targetFile.exists()) {
      return targetFile;
    }

    final tempFile = File('${targetFile.path}.tmp');

    try {
      await _dio.download(
        epubUrl,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
      );

      // Rename upon atomic complete download
      await tempFile.rename(targetFile.path);
      return targetFile;
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}
