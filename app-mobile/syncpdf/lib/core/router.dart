import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/activate/activate_screen.dart';
import '../screens/client/group_screen.dart';
import '../screens/client/home_screen.dart';
import '../screens/client/paywall_screen.dart';
import '../screens/client/pdf_viewer_screen.dart';
import '../screens/client/subscription_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/client_detail_screen.dart';
import '../screens/admin/clients_screen.dart';
import '../screens/forgot_password/forgot_password_screen.dart';
import '../screens/invite/invite_accept_screen.dart';
import '../screens/invite/pending_invitations_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/register/register_screen.dart';
import '../screens/superadmin/admins_screen.dart';
import '../screens/superadmin/settings_screen.dart';
import '../screens/superadmin/superadmin_dashboard_screen.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// Route path constants — keeps string literals in one place.
// ---------------------------------------------------------------------------

class AppRoutes {
  AppRoutes._();

  // Public — auth
  static const login = '/login';
  static const register = '/register';
  static const activate = '/activate';
  static const forgotPassword = '/forgot-password';

  // Public — invite (deep-link: syncpdf://invite?token=xxxxx)
  static const invite = '/invite';

  // Protected — invitations
  static const invitations = '/invitations';

  // Protected — main app (client)
  static const home = '/home';
  static const group = '/groups/:id';
  static const room = '/room/:id';
  static const subscription = '/subscription';
  static const paywall = '/paywall';

  // Protected — admin panel
  static const admin = '/admin';
  static const adminClients = '/admin/clients';
  static const adminClientDetail = '/admin/clients/:id';

  // Protected — superadmin panel
  static const superadmin = '/superadmin';
  static const superadminAdmins = '/superadmin/admins';
  static const superadminSettings = '/superadmin/settings';
}

// Routes that require an active subscription for client users.
const _subscriptionProtectedPaths = ['/home', '/groups', '/room'];

// ---------------------------------------------------------------------------
// Refresh notifier — bridges Riverpod state changes to GoRouter's
// refreshListenable so the GoRouter instance is created only ONCE and the
// redirect re-evaluates without recreating the entire router (which would
// tear down all mounted widgets and cause _dependents.isEmpty assertions).
// ---------------------------------------------------------------------------

class _GoRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Read initial values — do NOT watch (watching would rebuild this provider
  // on every change, recreating GoRouter and destroying the widget tree).
  var authState = ref.read(authNotifierProvider);
  var isActive = ref.read(isSubscriptionActiveProvider);

  // Notifier used to tell GoRouter to re-evaluate the redirect function
  // without recreating the router itself.
  final notifier = _GoRouterRefreshNotifier();

  // Listen for changes and update local vars, then trigger a redirect check.
  ref.listen<AuthState>(authNotifierProvider, (_, next) {
    authState = next;
    notifier.refresh();
  });

  ref.listen<bool>(isSubscriptionActiveProvider, (_, next) {
    isActive = next;
    notifier.refresh();
  });

  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      // While auth state is still being resolved (initial / loading), hold.
      final isLoading = switch (authState) {
        AuthInitial() || AuthLoading() => true,
        _ => false,
      };
      if (isLoading) return null;

      final isAuthenticated = switch (authState) {
        AuthAuthenticated() => true,
        _ => false,
      };

      final location = state.matchedLocation;

      final goingToPublic = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.activate ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.invite;

      // Authenticated users must not land on auth screens.
      if (isAuthenticated && goingToPublic && location != AppRoutes.invite) {
        return AppRoutes.home;
      }

      // Unauthenticated users must not reach protected screens.
      if (!isAuthenticated && !goingToPublic) {
        return AppRoutes.login;
      }

      if (isAuthenticated) {
        final user = switch (authState) {
          AuthAuthenticated(:final user) => user,
          _ => null,
        };

        // Role guards — enforce access boundaries between roles.
        // clients must not reach admin or superadmin areas.
        if (user?.role == 'client') {
          if (location.startsWith('/admin') ||
              location.startsWith('/superadmin')) {
            return AppRoutes.home;
          }
        }
        // admins must not reach superadmin-only areas.
        if (user?.role == 'admin') {
          if (location.startsWith('/superadmin')) {
            return AppRoutes.admin;
          }
        }

        // Subscription guard — client users without active subscription cannot
        // access home, groups, or rooms; redirect them to the paywall.
        if (user?.role == 'client' &&
            !isActive &&
            _subscriptionProtectedPaths
                .any((p) => location.startsWith(p))) {
          // Allow paywall and subscription screens through.
          if (location != AppRoutes.paywall &&
              location != AppRoutes.subscription) {
            return AppRoutes.paywall;
          }
        }
      }

      return null;
    },
    routes: [
      // -----------------------------------------------------------------------
      // Public — auth screens
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) {
          // When arriving from InviteAcceptScreen, extra carries the token.
          final inviteToken = state.extra as String?;
          return RegisterScreen(inviteToken: inviteToken);
        },
      ),
      GoRoute(
        path: AppRoutes.activate,
        builder: (context, state) {
          // Email is passed as `extra` from RegisterScreen.
          final email = state.extra as String? ?? '';
          return ActivateScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // -----------------------------------------------------------------------
      // Public — deep-link invite (does not require auth)
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.invite,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return InviteAcceptScreen(token: token);
        },
      ),

      // -----------------------------------------------------------------------
      // Protected — requires authentication (and active subscription for client)
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.group,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GroupScreen(groupId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.room,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // role is passed as a query parameter: /room/:id?role=host|viewer
          // Default to 'viewer' — the server enforces the actual role anyway.
          final role = state.uri.queryParameters['role'] ?? 'viewer';
          return PDFViewerScreen(roomId: id, role: role);
        },
      ),
      GoRoute(
        path: AppRoutes.paywall,
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.invitations,
        builder: (context, state) => const PendingInvitationsScreen(),
      ),

      // -----------------------------------------------------------------------
      // Protected — admin panel (role: admin | superadmin)
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminClients,
        builder: (context, state) => const ClientsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminClientDetail,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClientDetailScreen(clientId: id);
        },
      ),

      // -----------------------------------------------------------------------
      // Protected — superadmin panel (role: superadmin only)
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.superadmin,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.superadminAdmins,
        builder: (context, state) => const AdminsScreen(),
      ),
      GoRoute(
        path: AppRoutes.superadminSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
