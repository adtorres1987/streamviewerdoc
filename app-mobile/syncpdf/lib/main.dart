import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'app.dart';
import 'core/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe must be initialised before the widget tree is built.
  // The key comes from --dart-define=STRIPE_PUBLISHABLE_KEY=pk_...
  // Skip init in dev if no key is provided (payments will fail gracefully).
  if (AppConstants.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const ProviderScope(child: SyncPDFApp()));
}
