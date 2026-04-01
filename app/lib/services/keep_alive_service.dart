import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class KeepAliveService {
  static KeepAliveService? _instance;
  Timer? _timer;

  KeepAliveService._();

  static void start() {
    _instance ??= KeepAliveService._();
    _instance!._timer?.cancel();
    // Ping immediately, then every 10 minutes
    _instance!._ping();
    _instance!._timer = Timer.periodic(const Duration(minutes: 10), (_) {
      _instance!._ping();
    });
  }

  static void stop() {
    _instance?._timer?.cancel();
    _instance?._timer = null;
  }

  void _ping() async {
    try {
      await apiClient.get('/health');
    } catch (e) {
      debugPrint('Keep-alive ping failed: $e');
    }
  }
}
