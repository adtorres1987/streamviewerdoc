import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/client_detail.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../providers/auth_provider.dart';

/// Shows a single client's details and provides admin actions:
/// suspend/activate, and edit trial end date.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del cliente'),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(clientDetailProvider(clientId)),
        ),
        data: (client) => _ClientDetailView(
          client: client,
          onRefresh: () => ref.invalidate(clientDetailProvider(clientId)),
          clientId: clientId,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content view
// ---------------------------------------------------------------------------

class _ClientDetailView extends ConsumerWidget {
  const _ClientDetailView({
    required this.client,
    required this.onRefresh,
    required this.clientId,
  });

  final ClientDetail client;
  final VoidCallback onRefresh;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF4F46E5).withOpacity(0.12),
                    child: const Icon(
                      Icons.person,
                      size: 28,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.fullName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client.email,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Info card
          Card(
            child: Column(
              children: [
                _InfoRow(
                  label: 'Estado de cuenta',
                  value: _accountStatusLabel(client.status),
                  valueColor: _accountStatusColor(client.status),
                ),
                const Divider(height: 1),
                _InfoRow(
                  label: 'Suscripción',
                  value: _subStatusLabel(client.subscriptionStatus),
                  valueColor: _subStatusColor(client.subscriptionStatus),
                ),
                if (client.trialEndsAt != null) ...[
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Trial termina',
                    value: dateFormat.format(client.trialEndsAt!),
                  ),
                ],
                if (client.currentPeriodEnd != null) ...[
                  const Divider(height: 1),
                  _InfoRow(
                    label: 'Periodo actual termina',
                    value: dateFormat.format(client.currentPeriodEnd!),
                  ),
                ],
                const Divider(height: 1),
                _InfoRow(
                  label: 'Miembro desde',
                  value: dateFormat.format(client.createdAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (client.status == 'suspended')
            FilledButton.icon(
              onPressed: () => _activateClient(context, ref),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Activar cliente'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _suspendClient(context, ref),
              icon: const Icon(Icons.block),
              label: const Text('Suspender cliente'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () => _editTrial(context, ref),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Editar trial'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _suspendClient(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspender cliente'),
        content: Text(
          '¿Seguro que quieres suspender a ${client.fullName}? No podrá acceder a la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspender'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final token = _token(ref);
      await AdminService(token).suspendClient(clientId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente suspendido.')),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _activateClient(BuildContext context, WidgetRef ref) async {
    try {
      final token = _token(ref);
      await AdminService(token).activateClient(clientId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente activado.')),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _editTrial(BuildContext context, WidgetRef ref) async {
    final initialDate = client.trialEndsAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecciona la nueva fecha de fin de trial',
    );

    if (picked == null || !context.mounted) return;

    try {
      final token = _token(ref);
      await AdminService(token).editClientTrial(clientId, picked);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trial actualizado.')),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  String _token(WidgetRef ref) {
    final authState = ref.read(authNotifierProvider);
    return switch (authState) {
      AuthAuthenticated(:final token) => token,
      _ => throw StateError('Not authenticated'),
    };
  }

  // --------------------------------------------------------------------------
  // Label / color helpers
  // --------------------------------------------------------------------------

  String _accountStatusLabel(String status) => switch (status) {
        'active' => 'Activo',
        'suspended' => 'Suspendido',
        'pending' => 'Pendiente',
        _ => status,
      };

  Color _accountStatusColor(String status) => switch (status) {
        'active' => Colors.green,
        'suspended' => Colors.grey,
        _ => Colors.orange,
      };

  String _subStatusLabel(String? status) => switch (status) {
        'active' => 'Activo',
        'trial' => 'Trial',
        'expired' => 'Expirado',
        'cancelled' => 'Cancelado',
        _ => 'Sin suscripción',
      };

  Color _subStatusColor(String? status) => switch (status) {
        'active' => Colors.green,
        'trial' => Colors.blue,
        'expired' || 'cancelled' => Colors.red,
        _ => Colors.grey,
      };
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
