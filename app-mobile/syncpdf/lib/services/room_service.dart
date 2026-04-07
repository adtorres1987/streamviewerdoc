import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/room.dart';

/// Handles all HTTP calls to `/rooms/*` endpoints.
/// Throws typed [AppException] subclasses — never raw [DioException].
class RoomService {
  RoomService()
      : _dio = _buildDio(),
        _storage = const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

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

  /// GET /rooms?groupId=<id>
  Future<List<Room>> getRooms(String groupId) async {
    final data = await _get('/rooms', queryParameters: {'groupId': groupId});
    final list = data as List<dynamic>;
    return list
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /rooms/:id — returns room detail including participants.
  Future<Room> getRoom(String id) async {
    final data = await _get('/rooms/$id');
    return Room.fromJson(data as Map<String, dynamic>);
  }

  /// POST /rooms — creates a new room. Requires active subscription.
  Future<Room> createRoom(String groupId, String name) async {
    final data = await _post('/rooms', {'groupId': groupId, 'name': name});
    return Room.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /rooms/:id/close — closes the room (host only).
  Future<Room> closeRoom(String id) async {
    final data = await _patch('/rooms/$id/close');
    return Room.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /rooms/:id — deletes the room (group owner only).
  Future<void> deleteRoom(String id) async {
    await _delete('/rooms/$id');
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return (response.data ?? {})['data'];
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final options = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: options,
      );
      return (response.data ?? {})['data'];
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<void> _delete(String path) async {
    try {
      final options = await _authOptions();
      await _dio.delete<void>(path, options: options);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<dynamic> _patch(String path) async {
    try {
      final options = await _authOptions();
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        options: options,
      );
      return (response.data ?? {})['data'];
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<Options> _authOptions() async {
    final token = await _storage.read(key: AppConstants.tokenStorageKey);
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

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
      return AuthException(serverMessage ?? 'Access denied.');
    }

    if (statusCode != null && statusCode >= 400) {
      return ServerException.withStatus(
        statusCode,
        serverMessage ?? 'Server error ($statusCode).',
      );
    }

    return UnknownException(e.message ?? 'Unexpected error.');
  }

  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return (body['message'] ?? body['error']) as String?;
    }
    return null;
  }
}
