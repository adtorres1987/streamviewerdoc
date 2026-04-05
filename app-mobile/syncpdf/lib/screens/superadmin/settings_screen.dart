import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/global_settings.dart';
import '../../providers/superadmin_provider.dart';

/// Displays and edits global app settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración global'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(settingsProvider),
        ),
        data: (settings) => _SettingsForm(settings: settings),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings form
// ---------------------------------------------------------------------------

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final GlobalSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _trialDaysController;
  late final TextEditingController _reconnectTimeoutController;
  late final TextEditingController _scrollDebounceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _trialDaysController = TextEditingController(
      text: widget.settings.defaultTrialDays.toString(),
    );
    _reconnectTimeoutController = TextEditingController(
      text: widget.settings.hostReconnectTimeoutMin.toString(),
    );
    _scrollDebounceController = TextEditingController(
      text: widget.settings.scrollDebounceMs.toString(),
    );
  }

  @override
  void dispose() {
    _trialDaysController.dispose();
    _reconnectTimeoutController.dispose();
    _scrollDebounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suscripciones',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _IntField(
                      controller: _trialDaysController,
                      label: 'Días de trial por defecto',
                      helperText: 'Días de acceso gratuito para nuevos clientes.',
                      min: 1,
                      max: 365,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WebSocket',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _IntField(
                      controller: _reconnectTimeoutController,
                      label: 'Timeout de reconexión del host (min)',
                      helperText:
                          'Minutos que el host tiene para reconectarse antes de cerrar la sala.',
                      min: 1,
                      max: 60,
                    ),
                    const SizedBox(height: 12),
                    _IntField(
                      controller: _scrollDebounceController,
                      label: 'Debounce de scroll (ms)',
                      helperText:
                          'Milisegundos de espera antes de persistir la posición de scroll.',
                      min: 100,
                      max: 30000,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(settingsProvider.notifier).updateSettings({
        'default_trial_days': int.parse(_trialDaysController.text.trim()),
        'host_reconnect_timeout_min':
            int.parse(_reconnectTimeoutController.text.trim()),
        'scroll_debounce_ms':
            int.parse(_scrollDebounceController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Integer form field with validation
// ---------------------------------------------------------------------------

class _IntField extends StatelessWidget {
  const _IntField({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Este campo es requerido';
        final n = int.tryParse(v);
        if (n == null) return 'Debe ser un número entero';
        if (n < min || n > max) return 'Debe estar entre $min y $max';
        return null;
      },
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
