import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// Handles all HTTP calls to `/superadmin/*` endpoints.
/// Throws typed [AppException] subclasses — never raw [DioException].
class SuperAdminService {
  SuperAdminService(this._token) : _dio = _buildDio();

  final String _token;
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

  Options get _authOptions =>
      Options(headers: {'Authorization': 'Bearer $_token'});

  // --------------------------------------------------------------------------
  // Admins
  // --------------------------------------------------------------------------

  /// GET /superadmin/admins — returns the list of admins with `clients_count`.
  Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/superadmin/admins',
        options: _authOptions,
      );
      final data = (response.data?['data'] as List<dynamic>?) ?? [];
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// POST /superadmin/admins/invite — sends an invitation email to the admin.
  Future<void> inviteAdmin(String email, String fullName) async {
    try {
      await _dio.post<void>(
        '/superadmin/admins/invite',
        data: {'email': email, 'full_name': fullName},
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// PATCH /superadmin/admins/:id/suspend
  Future<void> suspendAdmin(String id) async {
    try {
      await _dio.patch<void>(
        '/superadmin/admins/$id/suspend',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// PATCH /superadmin/admins/:id/activate
  Future<void> activateAdmin(String id) async {
    try {
      await _dio.patch<void>(
        '/superadmin/admins/$id/activate',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Settings
  // --------------------------------------------------------------------------

  /// GET /superadmin/settings — returns the raw settings map from `data`.
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/superadmin/settings',
        options: _authOptions,
      );
      return (response.data?['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// PATCH /superadmin/settings — updates global settings.
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _dio.patch<void>(
        '/superadmin/settings',
        data: settings,
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Metrics
  // --------------------------------------------------------------------------

  /// GET /superadmin/metrics — returns the raw metrics map from `data`.
  Future<Map<String, dynamic>> getMetrics() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/superadmin/metrics',
        options: _authOptions,
      );
      return (response.data?['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  // --------------------------------------------------------------------------
  // Error mapping
  // --------------------------------------------------------------------------

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
      return AuthException(serverMessage ?? 'No tienes permisos para esta acción.');
    }

    if (statusCode != null && statusCode >= 400) {
      return ServerException.withStatus(
        statusCode,
        serverMessage ?? 'Error del servidor ($statusCode).',
      );
    }

    return UnknownException(e.message ?? 'Error inesperado.');
  }

  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return (body['message'] ?? body['error']) as String?;
    }
    return null;
  }
}
