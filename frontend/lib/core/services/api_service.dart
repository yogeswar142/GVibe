import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  // Retrieve the base URL from the .env file.
  // If not found, it defaults to the emulator localhost IP.
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:5000/api';

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Auth interceptor — attaches JWT token to all requests
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Log errors for debugging
        print('❌ API Error: ${error.requestOptions.method} ${error.requestOptions.path} → ${error.response?.statusCode}');
        print('   ${error.response?.data}');
        return handler.next(error);
      },
    ));
  }
}
