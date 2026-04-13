import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/plan.dart';
import '../../providers/subscription_provider.dart';
import '../../services/payment_service.dart';
import '../../services/subscription_service.dart';

/// Shows available subscription plans and lets the user subscribe.
///
/// On subscribe the backend creates a Stripe subscription with a trial period.
/// Stripe will charge the card automatically when the trial ends via webhook —
/// no payment sheet is shown here.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Plan>? _plans;
  Object? _error;
  bool _loading = true;

  // Tracks which planId is currently being subscribed to.
  String? _subscribingPlanId;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await SubscriptionService().getPlans();
      if (mounted) setState(() => _plans = plans);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error.toString(), onRetry: _loadPlans)
              : _PlanList(
                  plans: _plans ?? [],
                  subscribingPlanId: _subscribingPlanId,
                  onSubscribe: _subscribe,
                ),
    );
  }

  Future<void> _subscribe(Plan plan) async {
    setState(() => _subscribingPlanId = plan.id);
    try {
      await PaymentService().subscribe(plan.id);
      // Force subscription badge and subscription screen to re-fetch.
      ref.invalidate(subscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '¡Suscripción iniciada! Periodo de prueba activo.'),
          ),
        );
        // PaywallScreen may be shown via GoRouter redirect (go), leaving no
        // parent route to pop back to. Fall back to going home.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribingPlanId = null);
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.plans,
    required this.subscribingPlanId,
    required this.onSubscribe,
  });

  final List<Plan> plans;
  final String? subscribingPlanId;
  final void Function(Plan) onSubscribe;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const Center(child: Text('No hay planes disponibles.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...plans.asMap().entries.map((entry) {
          final i = entry.key;
          final plan = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < plans.length - 1 ? 12 : 0),
            child: _PlanCard(
              plan: plan,
              isSubscribing: subscribingPlanId == plan.id,
              onSubscribe: () => onSubscribe(plan),
            ),
          );
        }),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Al finalizar el período de prueba, Stripe procesará el pago automáticamente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSubscribing,
    required this.onSubscribe,
  });

  final Plan plan;
  final bool isSubscribing;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${plan.priceUsd.toStringAsFixed(2)}/mes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF4F46E5),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${plan.durationDays} días de acceso',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubscribing ? null : onSubscribe,
                child: isSubscribing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Suscribirse'),
              ),
            ),
          ],
        ),
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
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
