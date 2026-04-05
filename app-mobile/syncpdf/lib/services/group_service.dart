import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/group.dart';

/// Handles all HTTP calls to `/groups/*` endpoints.
/// Throws typed [AppException] subclasses — never raw [DioException].
class GroupService {
  GroupService()
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

  /// GET /groups — returns groups the current user belongs to.
  Future<List<Group>> getGroups() async {
    final data = await _get('/groups');
    final list = data as List<dynamic>;
    return list
        .map((e) => Group.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /groups/:id — returns group detail including members list.
  Future<Group> getGroup(String id) async {
    final data = await _get('/groups/$id');
    return Group.fromJson(data as Map<String, dynamic>);
  }

  /// POST /groups — creates a new group. Requires active subscription.
  Future<Group> createGroup(String name) async {
    final data = await _post('/groups', {'name': name});
    return Group.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /groups/:id — deletes the group (owner only).
  Future<void> deleteGroup(String id) async {
    await _delete('/groups/$id');
  }

  /// POST /groups/:id/invite — invites a user by email.
  /// Returns `{ token, invitedEmail, expiresAt }`.
  Future<Map<String, dynamic>> inviteToGroup(
    String groupId,
    String email,
  ) async {
    final data = await _post('/groups/$groupId/invite', {'email': email});
    return data as Map<String, dynamic>;
  }

  /// GET /groups/invite/:token — validates an invitation token (public).
  /// Returns `{ groupId, groupName, invitedEmail, expiresAt }`.
  Future<Map<String, dynamic>> validateInvite(String token) async {
    final data = await _get('/groups/invite/$token', requiresAuth: false);
    return data as Map<String, dynamic>;
  }

  /// POST /groups/invite/:token/accept — authenticated user accepts invite.
  Future<void> acceptInvite(String token) async {
    await _post('/groups/invite/$token/accept', {});
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Returns the `data` field from `{ success: true, data: ... }`.
  Future<dynamic> _get(
    String path, {
    bool requiresAuth = true,
  }) async {
    try {
      final options = requiresAuth ? await _authOptions() : null;
      final response = await _dio.get<Map<String, dynamic>>(
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
