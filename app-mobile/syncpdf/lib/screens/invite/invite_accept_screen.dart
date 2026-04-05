import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';

/// Handles deep-link invite flow: `syncpdf://invite?token=xxxxx`
///
/// - Unauthenticated → pushes to `/register` with token as extra
/// - Authenticated → shows group name + confirm dialog, then accepts invite
class InviteAcceptScreen extends ConsumerStatefulWidget {
  const InviteAcceptScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<InviteAcceptScreen> createState() =>
      _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  Map<String, dynamic>? _inviteData;
  Object? _error;
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _validateToken();
  }

  Future<void> _validateToken() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await GroupService().validateInvite(widget.token);
      if (mounted) setState(() => _inviteData = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptInvite() async {
    // Guard: user must be authenticated to accept.
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState is AuthAuthenticated;
    if (!isAuthenticated) {
      // Push to register with token so it can be consumed after account setup.
      context.push('/register', extra: widget.token);
      return;
    }

    setState(() => _accepting = true);
    try {
      await GroupService().acceptInvite(widget.token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te has unido al grupo.')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitación')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(
                  message: _error.toString(), onRetry: _validateToken)
              : _InviteDetail(
                  inviteData: _inviteData!,
                  accepting: _accepting,
                  onAccept: _acceptInvite,
                  onDecline: () => context.pop(),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InviteDetail extends StatelessWidget {
  const _InviteDetail({
    required this.inviteData,
    required this.accepting,
    required this.onAccept,
    required this.onDecline,
  });

  final Map<String, dynamic> inviteData;
  final bool accepting;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final groupName = inviteData['groupName'] as String? ?? '-';
    final invitedEmail = inviteData['invitedEmail'] as String? ?? '-';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.group_add, size: 72, color: Color(0xFF4F46E5)),
          const SizedBox(height: 24),
          Text(
            'Fuiste invitado a unirte a',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            groupName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Invitación para: $invitedEmail',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: accepting ? null : onAccept,
              child: accepting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Unirme al grupo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: accepting ? null : onDecline,
              child: const Text('Rechazar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Invitación inválida o expirada',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
