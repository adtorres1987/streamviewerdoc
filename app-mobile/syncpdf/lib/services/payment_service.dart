import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import '../core/exceptions.dart';

/// Thin Stripe-specific payment service.
///
/// The current flow is trial-based: subscribing calls the backend which creates
/// a Stripe subscription with a trial period. Stripe charges the card
/// automatically when the trial ends via webhook — no client-side
/// PaymentIntent/SetupIntent is needed at this stage.
///
/// When a PaymentIntent flow is required in the future, initialise
/// [Stripe.instance] here and present the payment sheet.
class PaymentService {
  PaymentService()
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

  /// Calls POST /payments/subscribe with [planId].
  ///
  /// Returns the raw subscription data: `{ subscriptionId, status, trialEndsAt }`.
  /// For plans with a trial, the subscription is created server-side and Stripe
  /// will charge automatically at trial end. No payment sheet is shown here.
  Future<Map<String, dynamic>> subscribe(String planId) async {
    return _post('/payments/subscribe', {'planId': planId});
  }

  /// Calls POST /payments/cancel — sets cancel_at_period_end: true on Stripe.
  /// Access continues until the current period ends.
  Future<void> cancel() async {
    await _post('/payments/cancel', {});
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final options = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: options,
      );
      final data = (response.data ?? {})['data'];
      if (data is Map<String, dynamic>) return data;
      // Some endpoints (e.g. cancel) may return null data on success.
      return const {};
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw UnknownException(e.toString());
    }
  }

  Future<Options> _authOptions() async {
    final token = await _storage.read(key: AppConstants.tokenStorageKey);
    if (token == null) throw const AuthException('No autenticado.');
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
      return AuthException(serverMessage ?? 'Acceso denegado.');
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
