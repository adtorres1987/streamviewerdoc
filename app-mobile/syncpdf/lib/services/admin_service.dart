import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

/// Handles all HTTP calls to `/admin/*` endpoints.
/// Throws typed [AppException] subclasses — never raw [DioException].
class AdminService {
  AdminService(this._token) : _dio = _buildDio();

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
  // Clients
  // --------------------------------------------------------------------------

  /// GET /admin/clients — returns the raw list from `data`.
  /// Pass [q] for server-side search.
  Future<List<Map<String, dynamic>>> getClients({String? q}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/clients',
        queryParameters: q != null && q.isNotEmpty ? {'q': q} : null,
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

  /// GET /admin/clients/:id — returns the raw client detail map from `data`.
  Future<Map<String, dynamic>> getClientDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/clients/$id',
        options: _authOptions,
      );
      return (response.data?['data'] as Map<String, dynamic>?) ?? {};
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// PATCH /admin/clients/:id/suspend
  Future<void> suspendClient(String id) async {
    try {
      await _dio.patch<void>(
        '/admin/clients/$id/suspend',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// PATCH /admin/clients/:id/activate
  Future<void> activateClient(String id) async {
    try {
      await _dio.patch<void>(
        '/admin/clients/$id/activate',
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// PATCH /admin/clients/:id/trial — updates the trial end date.
  Future<void> editClientTrial(String id, DateTime trialEndsAt) async {
    try {
      await _dio.patch<void>(
        '/admin/clients/$id/trial',
        data: {'trial_ends_at': trialEndsAt.toUtc().toIso8601String()},
        options: _authOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  /// GET /admin/rooms/active — returns the list of currently active rooms.
  Future<List<Map<String, dynamic>>> getActiveRooms() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/rooms/active',
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
