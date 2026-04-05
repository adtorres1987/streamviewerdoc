/// All environment values are injected via --dart-define at build time.
/// Never hardcode URLs or keys here.
class AppConstants {
  AppConstants._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:3000/ws',
  );

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String appName = 'SyncPDF';

  // Timing constants (milliseconds / seconds)
  static const int scrollDebounceMsHost = 50;
  static const int viewerPersistDebounceMs = 5000;
  static const int heartbeatIntervalSec = 30;

  // Reconnect backoff steps (seconds)
  static const List<int> reconnectBackoffSeconds = [1, 2, 4, 8, 16, 30];

  // Secure storage key for the JWT — must match the key used in AuthNotifier.
  static const String tokenStorageKey = 'syncpdf_auth_token';
}
