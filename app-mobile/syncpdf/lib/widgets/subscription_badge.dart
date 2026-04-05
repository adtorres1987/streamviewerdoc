import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription.dart';
import '../providers/subscription_provider.dart';

/// Displays a colored status chip reflecting the current subscription state.
///
/// States:
///   - Loading              → small activity indicator
///   - trial                → amber chip: "Trial · X días"
///   - active               → green chip: "Activo"
///   - active + cancelledAt → orange chip: "Cancelando"
///   - expired              → red chip: "Expirado"
///   - cancelled            → grey chip: "Cancelado"
class SubscriptionBadge extends ConsumerWidget {
  const SubscriptionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return subAsync.when(
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (sub) {
        final Color color;
        final String label;

        switch (sub.status) {
          case 'trial':
            color = Colors.amber.shade700;
            label = 'Trial · ${sub.daysRemaining} días';
          case 'active':
            // If cancel_at_period_end is set, cancelledAt is non-null even
            // though status is still 'active' until the period ends.
            if (sub.cancelledAt != null) {
              color = Colors.orange.shade700;
              label = 'Cancelando';
            } else {
              color = Colors.green.shade700;
              label = 'Activo';
            }
          case 'cancelled':
            if (sub.isCancellingAtPeriodEnd) {
              // Access still valid until currentPeriodEnd.
              color = Colors.orange.shade700;
              label = 'Cancelando';
            } else {
              color = Colors.grey.shade600;
              label = 'Cancelado';
            }
          default:
            color = Colors.red.shade700;
            label = 'Expirado';
        }

        return Chip(
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          side: BorderSide.none,
        );
      },
    );
  }
}
