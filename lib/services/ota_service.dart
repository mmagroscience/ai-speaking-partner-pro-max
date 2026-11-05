import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../data/models.dart';

class OtaService {
  OtaService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<OtaConfig> fetch({String url = ''}) async {
    if (url.trim().isNotEmpty) {
      try {
        final response = await _client
            .get(Uri.parse(url.trim()))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return OtaConfig.fromJson(decoded);
          }
          if (decoded is Map) {
            return OtaConfig.fromJson(decoded.cast<String, dynamic>());
          }
        }
      } catch (_) {
        // Network, CORS, or invalid JSON — fall back to the bundled config.
      }
    }
    return loadBundled();
  }

  Future<OtaConfig> loadBundled() async {
    try {
      final raw = await rootBundle.loadString('assets/ota_config.json');
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return OtaConfig.fromJson(decoded);
      }
    } catch (_) {}
    return const OtaConfig(
      latestVersionCode: AppInfoVersion.code,
      latestVersionName: AppInfoVersion.name,
      apkUrl: '',
      changelog: '',
    );
  }

  void dispose() => _client.close();
}
