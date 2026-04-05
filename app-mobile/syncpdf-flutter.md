# SyncPDF — Flutter App Architecture

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter (Dart) |
| Estado | flutter_riverpod |
| Navegación | go_router |
| PDF Viewer | syncfusion_flutter_pdfviewer |
| WebSocket | web_socket_channel |
| Pagos | flutter_stripe |
| Auth / DB client | supabase_flutter |
| Push notifications | firebase_messaging |
| Selector de archivos | file_picker |
| Almacenamiento local | shared_preferences |

---

## pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # PDF
  syncfusion_flutter_pdfviewer: ^24.0.0

  # Estado
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navegación
  go_router: ^13.0.0

  # WebSocket
  web_socket_channel: ^2.4.0

  # Pagos
  flutter_stripe: ^10.0.0

  # Backend / Auth
  supabase_flutter: ^2.3.0

  # Archivos
  file_picker: ^8.0.0

  # Push
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.0.0

  # Utilidades
  uuid: ^4.0.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0

dev_dependencies:
  riverpod_generator: ^2.3.0
  build_runner: ^2.4.0
```

---

## Estructura de archivos

```
lib/
├── main.dart
├── app.dart                            # MaterialApp + GoRouter
│
├── core/
│   ├── router.dart                     # Rutas + guards de rol y suscripción
│   ├── theme.dart                      # Colores, tipografía, estilos
│   ├── constants.dart                  # URLs, timeouts, keys
│   └── exceptions.dart                 # Excepciones tipadas
│
├── models/
│   ├── user.dart
│   ├── subscription.dart
│   ├── group.dart
│   ├── group_member.dart
│   ├── room.dart
│   ├── room_participant.dart
│   ├── plan.dart
│   └── sync_event.dart                 # Sealed class — mensajes WS
│
├── services/
│   ├── auth_service.dart
│   ├── group_service.dart
│   ├── room_service.dart
│   ├── subscription_service.dart
│   ├── payment_service.dart
│   ├── sync_service.dart               # WebSocket client
│   └── pdf_service.dart                # Carga y validación PDF
│
├── providers/
│   ├── auth_provider.dart
│   ├── group_provider.dart
│   ├── room_provider.dart
│   ├── subscription_provider.dart
│   └── sync_provider.dart
│
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── activate_screen.dart        # Código de activación (admin)
│   │   └── forgot_password_screen.dart
│   │
│   ├── client/
│   │   ├── home_screen.dart            # Lista de grupos
│   │   ├── group_screen.dart           # Salas del grupo
│   │   ├── pdf_viewer_screen.dart      # Visor PDF + sync
│   │   ├── subscription_screen.dart    # Estado de suscripción
│   │   └── paywall_screen.dart         # Planes + pago
│   │
│   ├── admin/
│   │   ├── dashboard_screen.dart
│   │   ├── clients_screen.dart
│   │   └── client_detail_screen.dart
│   │
│   └── superadmin/
│       ├── dashboard_screen.dart
│       ├── admins_screen.dart
│       ├── settings_screen.dart        # Trial días, precios
│       └── metrics_screen.dart
│
└── widgets/
    ├── sync_banner.dart                # Banner de estado de conexión
    ├── reconnect_banner.dart           # Banner host reconectó
    ├── page_indicator.dart             # Pág. X / Y
    ├── room_overlay.dart               # Panel código + participantes
    ├── subscription_badge.dart         # Trial / Activo / Expirado
    └── avatar.dart
```

---

## Modelos

### SyncEvent — sealed class
```dart
sealed class SyncEvent {}

class RoomJoined        extends SyncEvent { final String roomId; final String code; }
class ScrollSync        extends SyncEvent { final int page; final double offsetY; }
class ParticipantsUpdate extends SyncEvent { final int count; }
class HostDisconnected  extends SyncEvent {
  final int lastPage;
  final double lastOffsetY;
  final int reconnectWindowSeconds;
}
class HostReconnected   extends SyncEvent {
  final int page;
  final double offsetY;
  final String hostName;
}
class RejoinContext     extends SyncEvent {
  final String roomStatus;
  final int yourLastPage;
  final double yourLastOffset;
  final int hostPage;
  final double hostOffset;
  final bool hostConnected;
  final String hostName;
}
class SessionClosed     extends SyncEvent { final String reason; }
class SyncError         extends SyncEvent { final String code; final String message; }
```

### RoomParticipant
```dart
class RoomParticipant {
  final String userId;
  final String fullName;
  final String role;         // 'host' | 'viewer'
  final String syncState;    // 'synced' | 'free' | 'disconnected'
  final int    lastPage;
  final double lastOffset;
}
```

### Subscription
```dart
class Subscription {
  final String    id;
  final String    status;       // 'trial' | 'active' | 'expired' | 'cancelled'
  final int       trialDays;
  final DateTime  trialEndsAt;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;

  bool get isActive {
    if (status == 'trial') return trialEndsAt.isAfter(DateTime.now());
    if (status == 'active') return currentPeriodEnd?.isAfter(DateTime.now()) ?? false;
    return false;
  }

  int get daysRemaining {
    final end = status == 'trial' ? trialEndsAt : currentPeriodEnd;
    return end?.difference(DateTime.now()).inDays ?? 0;
  }
}
```

---

## Providers — Riverpod

### authProvider
```dart
@riverpod
class Auth extends _$Auth {
  @override
  AsyncValue<User?> build() => const AsyncData(null);

  Future<void> login(String email, String password) async { ... }
  Future<void> register(String email, String password, String name) async { ... }
  Future<void> logout() async { ... }
}
```

### syncProvider
```dart
@riverpod
class Sync extends _$Sync {
  @override
  SyncState build() => SyncState.initial();

  void connect(String roomId, String role) { ... }
  void disconnect() { ... }
  void broadcastScroll(int page, double offsetY) { ... }
  void broadcastViewerScroll(int page, double offsetY) { ... }
  void rejoinSync() { ... }
}

class SyncState {
  final bool        isConnected;
  final String      viewerState;   // 'synced' | 'free' | 'disconnected'
  final String      bannerState;   // 'hidden' | 'host_disconnected' | 'host_reconnected'
  final int         participantCount;
  final HostInfo?   reconnectingHost;
}
```

---

## Máquina de estados del viewer

```dart
enum ViewerSyncState {
  synced,        // scroll bloqueado, siguiendo al host
  free,          // scroll libre (host caído o ignoró resync)
  disconnected,  // viewer sin conexión
}

// Transiciones:
// synced       → free          cuando llega HOST_DISCONNECTED
// synced       → disconnected  cuando se cae la red del viewer
// free         → synced        cuando viewer acepta REJOIN_SYNC
// disconnected → free          cuando viewer reconecta (restaura su posición)
// cualquiera   → closed        cuando llega SESSION_CLOSED
```

---

## SyncService — WebSocket client

```dart
class SyncService {

  // Conectar con JWT en query param
  void connect(String jwt) {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://api.syncpdf.app/ws?token=$jwt')
    );
    _listen();
    _startHeartbeat();    // PING cada 30s
  }

  // Reconexión automática con exponential backoff
  // Reintentos: 1s, 2s, 4s, 8s, 16s, máx 30s
  void _scheduleReconnect() { ... }

  // Unirse a sala — al reconectar usa el mismo roomId
  void joinRoom(String roomId) {
    _send({ 'type': 'JOIN_ROOM', 'roomId': roomId });
    _currentRoomId = roomId;    // para auto-rejoin
  }

  // Solo host
  void broadcastScroll(int page, double offsetY) {
    _send({ 'type': 'SCROLL', 'page': page, 'offsetY': offsetY });
  }

  // Solo viewers en modo libre — con debounce 5s
  void sendViewerScroll(int page, double offsetY) {
    _scrollDebouncer.run(() =>
      _send({ 'type': 'VIEWER_SCROLL', 'page': page, 'offsetY': offsetY })
    );
  }

  // Viewer acepta resync
  void rejoinSync(String roomId) {
    _send({ 'type': 'REJOIN_SYNC', 'roomId': roomId });
  }

  // Stream de eventos tipados
  Stream<SyncEvent> get events => _eventController.stream;
}
```

---

## PDFViewerScreen — lógica principal

```dart
class PDFViewerScreen extends ConsumerStatefulWidget { ... }

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {

  final PdfViewerController _pdfController = PdfViewerController();
  bool _suppressNextScroll = false;

  @override
  void initState() {
    super.initState();
    _listenToSyncEvents();
    if (widget.role == 'host') _setupHostScrollTracking();
  }

  // HOST: detectar scroll y broadcast
  void _setupHostScrollTracking() {
    _pdfController.addListener(() {
      final page    = _pdfController.pageNumber;
      final offsetY = _pdfController.scrollOffset.dy;
      ref.read(syncProvider.notifier).broadcastScroll(page, offsetY);
    });
  }

  // VIEWER: recibir sync y aplicar
  void _listenToSyncEvents() {
    ref.read(syncProvider.notifier).events.listen((event) {
      switch (event) {

        case ScrollSync(:final page, :final offsetY):
          if (widget.role == 'viewer') {
            _suppressNextScroll = true;
            _pdfController.jumpTo(yOffset: offsetY);
          }

        case RejoinContext(:final yourLastPage, :final yourLastOffset):
          // Restaurar posición personal del viewer
          _pdfController.jumpTo(yOffset: yourLastOffset);
          // El banner de resync lo muestra el syncProvider

        case HostReconnected():
          // El banner aparece automáticamente desde syncProvider
          // El viewer decide si acepta o no
          break;

        case SessionClosed():
          _showSessionClosedDialog();

        default:
          break;
      }
    });
  }

  // VIEWER: scroll libre (cuando host está desconectado)
  void _onViewerScrolled() {
    if (_suppressNextScroll) {
      _suppressNextScroll = false;
      return;
    }
    final syncState = ref.read(syncProvider).viewerState;
    if (syncState == 'free') {
      ref.read(syncProvider.notifier).broadcastViewerScroll(
        _pdfController.pageNumber,
        _pdfController.scrollOffset.dy,
      );
    }
  }
}
```

---

## Banners de estado

### ReconnectBanner

```dart
// Aparece en la parte inferior de PDFViewerScreen
// con slide-up animation

enum BannerState {
  hidden,
  hostDisconnected,   // "Carlos se desconectó · Navegando libremente"
  hostReconnected,    // "👋 Carlos volvió ¿Volver a sincro?" [Sí] [No]
  sessionClosed,      // "Sesión terminada"
}
```

**Comportamiento:**

| Evento WS recibido | Banner mostrado | Scroll viewer |
|---|---|---|
| `HOST_DISCONNECTED` | "Carlos se desconectó" | Libre |
| `HOST_RECONNECTED` | "Carlos volvió ¿Sincronizarme?" | Libre hasta que acepte |
| Viewer toca [Sí] | Desaparece | Bloqueado (synced) |
| Viewer toca [No] | Desaparece | Libre |
| `SESSION_CLOSED` | "Sesión terminada" + botón Cerrar | — |

---

## Navegación — GoRouter

```dart
final router = GoRouter(
  redirect: (context, state) {
    final auth   = ref.read(authProvider);
    final sub    = ref.read(subscriptionProvider);
    final isAuth = auth.value != null;

    // Sin sesión → login
    if (!isAuth) return '/login';

    // Suscripción vencida → paywall (solo clients)
    if (auth.value!.role == 'client' && !sub.isActive) return '/paywall';

    return null;
  },
  routes: [
    GoRoute(path: '/login',      builder: (_,__) => LoginScreen()),
    GoRoute(path: '/register',   builder: (_,__) => RegisterScreen()),
    GoRoute(path: '/activate',   builder: (_,__) => ActivateScreen()),
    GoRoute(path: '/paywall',    builder: (_,__) => PaywallScreen()),

    // Client
    GoRoute(path: '/home',       builder: (_,__) => HomeScreen()),
    GoRoute(path: '/groups/:id', builder: (_,s)  => GroupScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/room/:id',   builder: (_,s)  => PDFViewerScreen(roomId: s.pathParameters['id']!)),
    GoRoute(path: '/subscription', builder: (_,__) => SubscriptionScreen()),

    // Admin
    GoRoute(path: '/admin',      builder: (_,__) => AdminDashboard(),
      redirect: (ctx, _) => _requireRole(ctx, 'admin')),

    // SuperAdmin
    GoRoute(path: '/superadmin', builder: (_,__) => SuperAdminDashboard(),
      redirect: (ctx, _) => _requireRole(ctx, 'superadmin')),
  ],
);
```

---

## Pantallas por rol

### Client

| Pantalla | Descripción |
|---|---|
| `HomeScreen` | Lista de grupos del usuario |
| `GroupScreen` | Salas activas y pasadas del grupo, botón invitar |
| `PDFViewerScreen` | Visor PDF con sync, banners de estado |
| `SubscriptionScreen` | Días restantes, estado, botón cancelar |
| `PaywallScreen` | Planes disponibles, pago con Stripe |

### Admin

| Pantalla | Descripción |
|---|---|
| `AdminDashboard` | Resumen: clientes activos, en trial, expirados |
| `ClientsScreen` | Lista paginada de todos los clientes |
| `ClientDetailScreen` | Editar trial, suspender, ver grupos del cliente |

### SuperAdmin

| Pantalla | Descripción |
|---|---|
| `SuperAdminDashboard` | Métricas: usuarios, ingresos, salas activas |
| `AdminsScreen` | Lista de admins, invitar nuevo admin |
| `SettingsScreen` | Editar `default_trial_days`, precios de planes |
| `MetricsScreen` | Gráficas de crecimiento, churn, ingresos |

---

## Guard de acceso antes de crear/unirse a sala

```dart
Future<bool> checkRoomAccess(WidgetRef ref) async {
  final sub = ref.read(subscriptionProvider).value;
  if (sub == null) return false;

  if (sub.isActive) return true;

  // Redirigir a paywall
  ref.read(routerProvider).push('/paywall');
  return false;
}
```

---

## Flujo de invitación a grupo con deep link

```dart
// android/app/src/main/AndroidManifest.xml
// ios/Runner/Info.plist
// → registrar scheme: syncpdf://

// En GoRouter:
GoRoute(
  path: '/invite',
  builder: (_, state) => InviteAcceptScreen(
    token: state.queryParameters['token']!,
  ),
)

// Deep link: syncpdf://invite?token=xxxxx
// Si el usuario no tiene cuenta → RegisterScreen con token pre-cargado
// Si ya tiene cuenta → pantalla de confirmación "¿Unirte al grupo?"
```

---

## Consideraciones de rendimiento

**PDF pesados (100+ páginas):**
- `SfPdfViewer` renderiza páginas bajo demanda (lazy)
- No cargar todo el PDF en memoria
- Usar `initialScrollOffset` para restaurar posición sin scroll visible

**Scroll sync flood:**
- Host: debounce de 50ms en el listener del controller
- Viewer libre: debounce de 5s para persistencia en servidor
- Server solo reenvía a viewers con `syncState = 'synced'`

**Reconexión WebSocket:**
- Exponential backoff: 1s → 2s → 4s → 8s → 16s → 30s (máximo)
- Al reconectar: auto-rejoin con el último `roomId` en memoria
- Si la app estaba en background: reconectar al volver a foreground con `AppLifecycleListener`

---

## Variables de entorno

```dart
// lib/core/constants.dart
class Constants {
  static const apiUrl     = String.fromEnvironment('API_URL',
    defaultValue: 'https://api.syncpdf.app');
  static const wsUrl      = String.fromEnvironment('WS_URL',
    defaultValue: 'wss://api.syncpdf.app/ws');
  static const stripeKey  = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const scrollDebounceMs     = 50;
  static const viewerPersistDebounceMs = 5000;
  static const heartbeatIntervalSec = 30;
}
```
