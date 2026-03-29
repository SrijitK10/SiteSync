import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Dio apiClient = Dio(
  BaseOptions(
    baseUrl: 'https://rupayan.onrender.com',
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ),
)..interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      // Basic 401 handling could trigger a logout hook here
      return handler.next(e);
    },
  ),
);
