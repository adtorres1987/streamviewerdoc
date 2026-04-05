import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/subscription_badge.dart';

/// Shows the user's subscription status, key dates, and a cancel action.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Suscripción')),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(subscriptionProvider),
        ),
        data: (sub) => _SubscriptionDetail(sub: sub),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main detail body
// ---------------------------------------------------------------------------

class _SubscriptionDetail extends ConsumerStatefulWidget {
  const _SubscriptionDetail({required this.sub});
  final Subscription sub;

  @override
  ConsumerState<_SubscriptionDetail> createState() =>
      _SubscriptionDetailState();
}

class _SubscriptionDetailState extends ConsumerState<_SubscriptionDetail> {
  bool _cancelling = false;

  @override
  Widget build(BuildContext context) {
    final sub = widget.sub;
    final isCancelScheduled = sub.cancelledAt != null;
    final canCancel =
        (sub.status == 'trial' || sub.status == 'active') && !isCancelScheduled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge row
          Row(
            children: [
              Text(
                'Estado: ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              const SubscriptionBadge(),
            ],
          ),
          const SizedBox(height: 20),

          // Days-remaining progress bar (only for trial / active)
          if (sub.status == 'trial' || sub.status == 'active') ...[
            _DaysProgress(sub: sub),
            const SizedBox(height: 24),
          ],

          // Dates card
          _DatesCard(sub: sub),
          const SizedBox(height: 32),

          // Access-continues notice when cancel is already scheduled
          if (isCancelScheduled && sub.currentPeriodEnd != null) ...[
            _InfoBanner(
              icon: Icons.info_outline,
              color: Colors.orange.shade700,
              message:
                  'Acceso hasta: ${_fmtDate(sub.currentPeriodEnd!)}',
            ),
            const SizedBox(height: 16),
          ],

          // Cancel button — shown only when cancellation is NOT yet scheduled
          if (canCancel)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: _cancelling ? null : () => _confirmCancel(context),
                child: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Text('Cancelar suscripción'),
              ),
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.push('/paywall'),
              child: const Text('Ver planes'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar suscripción'),
        content: const Text(
          '¿Seguro? Mantendrás acceso hasta el fin del período actual. '
          'No se te cobrará en el siguiente ciclo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await PaymentService().cancel();
      ref.invalidate(subscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suscripción cancelada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  static String _fmtDate(DateTime date) =>
      DateFormat('d MMM yyyy', 'es').format(date);
}

// ---------------------------------------------------------------------------
// Days-remaining progress bar
// ---------------------------------------------------------------------------

class _DaysProgress extends StatelessWidget {
  const _DaysProgress({required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final totalDays = sub.status == 'trial'
        ? sub.trialDays
        : _periodLengthDays(sub);

    final remaining = sub.daysRemaining;
    final elapsed = (totalDays - remaining).clamp(0, totalDays);
    final progress = totalDays > 0 ? elapsed / totalDays : 0.0;

    final color = sub.status == 'trial'
        ? Colors.amber.shade700
        : Colors.green.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sub.status == 'trial' ? 'Período de prueba' : 'Período activo',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$remaining días restantes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  int _periodLengthDays(Subscription sub) {
    if (sub.currentPeriodEnd == null) return 30;
    // Estimate period as 30 days if we can't compute it accurately.
    return 30;
  }
}

// ---------------------------------------------------------------------------
// Dates detail card
// ---------------------------------------------------------------------------

class _DatesCard extends StatelessWidget {
  const _DatesCard({required this.sub});
  final Subscription sub;

  static String _fmtDate(DateTime date) =>
      DateFormat('d MMM yyyy', 'es').format(date);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
            if (sub.status == 'trial')
              _DateRow(
                label: 'Trial hasta',
                value: _fmtDate(sub.trialEndsAt),
              ),
            if (sub.currentPeriodEnd != null)
              _DateRow(
                label: sub.cancelledAt != null
                    ? 'Acceso hasta'
                    : 'Renovación',
                value: _fmtDate(sub.currentPeriodEnd!),
              ),
            if (sub.cancelledAt != null)
              _DateRow(
                label: 'Cancelado el',
                value: _fmtDate(sub.cancelledAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info banner (used for "access continues until" message)
// ---------------------------------------------------------------------------

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

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
