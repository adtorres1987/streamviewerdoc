import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_user.dart';
import '../../providers/superadmin_provider.dart';

/// Lists all admin users with their client counts.
/// Provides a FAB to invite a new admin, and inline suspend/activate actions.
class AdminsScreen extends ConsumerWidget {
  const AdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administradores'),
      ),
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(adminsProvider),
        ),
        data: (admins) => admins.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(adminsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  itemCount: admins.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    return _AdminTile(
                      admin: admin,
                      onSuspend: () =>
                          _suspendAdmin(context, ref, admin),
                      onActivate: () =>
                          _activateAdmin(context, ref, admin),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteDialog(context, ref),
        tooltip: 'Invitar admin',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  Future<void> _suspendAdmin(
    BuildContext context,
    WidgetRef ref,
    AdminUser admin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspender admin'),
        content: Text(
          '¿Seguro que quieres suspender a ${admin.fullName}?',
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
      await ref.read(adminsProvider.notifier).suspendAdmin(admin.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin suspendido.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _activateAdmin(
    BuildContext context,
    WidgetRef ref,
    AdminUser admin,
  ) async {
    try {
      await ref.read(adminsProvider.notifier).activateAdmin(admin.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin activado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_InviteData>(
      context: context,
      builder: (ctx) => const _InviteAdminDialog(),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref
          .read(adminsProvider.notifier)
          .inviteAdmin(result.email, result.fullName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitación enviada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Admin list tile
// ---------------------------------------------------------------------------

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.admin,
    required this.onSuspend,
    required this.onActivate,
  });

  final AdminUser admin;
  final VoidCallback onSuspend;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final isSuspended = admin.status == 'suspended';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuspended
              ? Colors.grey.withOpacity(0.15)
              : const Color(0xFF4F46E5).withOpacity(0.12),
          child: Icon(
            Icons.manage_accounts,
            color: isSuspended ? Colors.grey : const Color(0xFF4F46E5),
          ),
        ),
        title: Text(admin.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(admin.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              '${admin.clientsCount} cliente${admin.clientsCount != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: isSuspended
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline,
                    color: Colors.green),
                tooltip: 'Activar',
                onPressed: onActivate,
              )
            : IconButton(
                icon: const Icon(Icons.block, color: Colors.red),
                tooltip: 'Suspender',
                onPressed: onSuspend,
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invite dialog
// ---------------------------------------------------------------------------

class _InviteData {
  const _InviteData({required this.email, required this.fullName});
  final String email;
  final String fullName;
}

class _InviteAdminDialog extends StatefulWidget {
  const _InviteAdminDialog();

  @override
  State<_InviteAdminDialog> createState() => _InviteAdminDialogState();
}

class _InviteAdminDialogState extends State<_InviteAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invitar administrador'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa un email';
                if (!v.contains('@')) return 'Email inválido';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                _InviteData(
                  email: _emailController.text.trim(),
                  fullName: _nameController.text.trim(),
                ),
              );
            }
          },
          child: const Text('Invitar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No hay administradores registrados.'),
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
