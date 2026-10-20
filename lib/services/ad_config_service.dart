import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdConfigService {
  // Hardcoded Fallback URLs provided by Adsterra
  static const String fallbackBannerUrl =
      'https://asiafilm.org/4/2b6cc6af4c46295243d17a590353aef7';
  static const String fallbackDirectUrl =
      'https://asiafilm.org/4/3e1b5431f0c1512c95aebc5d7bc7f182';
  static const String fallbackReaderBannerUrl =
      'https://asiafilm.org/4/61cb63ab8d73ae6196e061645df75dad';

  // Dynamic In-Memory Configuration
  static String bannerAdUrl = fallbackBannerUrl;
  static String directAdUrl = fallbackDirectUrl;
  static String readerBannerAdUrl = fallbackReaderBannerUrl;
  static bool isAdsEnabled = true;
  static int adCountdownSeconds = 10;

  /// Fetches runtime configs from Supabase table `app_settings` (row id = 1).
  /// Gracefully catches network errors so the app never crashes offline.
  static Future<void> fetchAdConfig() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response != null) {
        if (response['banner_ad_url'] != null &&
            (response['banner_ad_url'] as String).isNotEmpty) {
          bannerAdUrl = response['banner_ad_url'] as String;
        }

        if (response['direct_ad_url'] != null &&
            (response['direct_ad_url'] as String).isNotEmpty) {
          directAdUrl = response['direct_ad_url'] as String;
        }

        if (response['reader_banner_ad_url'] != null &&
            (response['reader_banner_ad_url'] as String).isNotEmpty) {
          readerBannerAdUrl = response['reader_banner_ad_url'] as String;
        }

        if (response['is_ads_enabled'] != null) {
          isAdsEnabled = response['is_ads_enabled'] as bool;
        }

        if (response['ad_countdown_seconds'] != null) {
          adCountdownSeconds = (response['ad_countdown_seconds'] as num).toInt();
        }

        debugPrint(
            'AdConfigService: Loaded remote ad config successfully (isAdsEnabled: $isAdsEnabled, countdown: ${adCountdownSeconds}s)');
      }
    } catch (e) {
      debugPrint('AdConfigService: Error fetching remote config, using defaults: $e');
    }
  }
}
