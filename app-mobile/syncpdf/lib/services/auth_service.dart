import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// Handles all HTTP calls to `/auth/*` endpoints.
/// Throws typed [AppException] subclasses — never raw [DioException].
class AuthService {
  AuthService() : _dio = _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConstants.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Public methods
  // --------------------------------------------------------------------------

  /// POST /auth/login
  /// Returns the raw response body: `{ token, user, subscription }`.
  Future<Map<String, dynamic>> login(String email, String password) async {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  /// POST /auth/register
  /// Backend sends an activation code to [email] on success.
  Future<void> register(String email, String password, String fullName) async {
    await _post('/auth/register', {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
  }

  /// POST /auth/activate
  Future<void> activate(String email, String code) async {
    await _post('/auth/activate', {'email': email, 'code': code});
  }

  /// POST /auth/forgot-password
  /// Backend sends a password-reset code to [email].
  Future<void> forgotPassword(String email) async {
    await _post('/auth/forgot-password', {'email': email});
  }

  /// POST /auth/reset-password
  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await _post('/auth/reset-password', {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }

  /// GET /auth/me — validates [token] and returns `{ user, subscription }`.
  Future<Map<String, dynamic>> getMe(String token) async {
    return _get('/auth/me', token: token);
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      return response.data ?? {};
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? token,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return response.data ?? {};
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// Converts [DioException] into a typed [AppException].
  AppException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final serverMessage = _extractMessage(body);

    if (statusCode == 401 || statusCode == 403) {
      return AuthException(serverMessage ?? 'Invalid credentials.');
    }

    if (statusCode != null && statusCode >= 400) {
      return ServerException.withStatus(
        statusCode,
        serverMessage ?? 'Server error ($statusCode).',
      );
    }

    return UnknownException(e.message ?? 'Unexpected error.');
  }

  /// Tries to read `message` or `error` field from the response body.
  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return (body['message'] ?? body['error']) as String?;
    }
    return null;
  }
}
