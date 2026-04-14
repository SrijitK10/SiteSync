import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// In-memory JWT cache — avoids hitting SharedPreferences on every request.
String? _cachedJwt;

Future<String?> _loadJwt() async {
  if (_cachedJwt != null) return _cachedJwt;
  final prefs = await SharedPreferences.getInstance();
  _cachedJwt = prefs.getString('jwt');
  return _cachedJwt;
}

Future<void> setJwt(String? token) async {
  _cachedJwt = token;
  final prefs = await SharedPreferences.getInstance();
  if (token == null) {
    await prefs.remove('jwt');
  } else {
    await prefs.setString('jwt', token);
  }
}

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: 'https://rupayan.onrender.com',
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ),
)..interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _loadJwt();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      final prefs = await SharedPreferences.getInstance();
      final locale = prefs.getString('app_locale') ?? 'en';
      options.headers['Accept-Language'] = locale;

      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      return handler.next(e);
    },
  ),
);
