import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/plan.dart';
import '../models/subscription.dart';

/// Handles all HTTP calls to `/payments/*` endpoints.
/// Throws typed [AppException] subclasses — never raw [DioException].
class SubscriptionService {
  SubscriptionService()
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

  /// GET /payments/status — returns the current user's subscription.
  ///
  /// The API returns camelCase keys (`trialEndsAt`, `currentPeriodEnd`,
  /// `cancelledAt`). We normalise to the snake_case shape that
  /// [Subscription.fromJson] expects before deserialising.
  Future<Subscription> getStatus() async {
    final data = await _get('/payments/status') as Map<String, dynamic>;
    final normalised = <String, dynamic>{
      'id': data['id'] ?? '',
      'status': data['status'],
      'trial_days': data['trialDays'] ?? data['trial_days'] ?? 0,
      'trial_ends_at': data['trialEndsAt'] ?? data['trial_ends_at'],
      'current_period_end':
          data['currentPeriodEnd'] ?? data['current_period_end'],
      'cancelled_at': data['cancelledAt'] ?? data['cancelled_at'],
    };
    return Subscription.fromJson(normalised);
  }

  /// GET /payments/plans — returns available subscription plans.
  Future<List<Plan>> getPlans() async {
    final data = await _get('/payments/plans') as List<dynamic>;
    return data
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /payments/subscribe — creates a Stripe subscription for the user.
  /// Returns the raw response data: `{ subscriptionId, status, trialEndsAt }`.
  Future<Map<String, dynamic>> subscribe(String planId) async {
    final data = await _post('/payments/subscribe', {'planId': planId});
    return data as Map<String, dynamic>;
  }

  /// POST /payments/cancel — cancels the subscription at period end.
  Future<void> cancel() async {
    await _post('/payments/cancel', {});
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<dynamic> _get(String path) async {
    try {
      final options = await _authOptions();
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
