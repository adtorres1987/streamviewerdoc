import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../providers/admin_provider.dart';

/// Lists all clients managed by the current admin.
/// Supports 300ms-debounced server-side search.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _currentQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_currentQuery != value) {
        setState(() => _currentQuery = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuery.trim().isEmpty ? null : _currentQuery.trim();
    final clientsAsync = ref.watch(clientsProvider(q: q));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Buscar por nombre o email...',
              leading: const Icon(Icons.search),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(clientsProvider(q: q)),
              ),
              data: (clients) => clients.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(clientsProvider(q: q).notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        itemCount: clients.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return _ClientTile(
                            client: client,
                            onTap: () {
                              final id = client['id'] as String;
                              context.push(
                                AppRoutes.adminClientDetail
                                    .replaceFirst(':id', id),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Client list tile
// ---------------------------------------------------------------------------

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client, required this.onTap});

  final Map<String, dynamic> client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fullName = client['full_name'] as String? ?? '—';
    final email = client['email'] as String? ?? '—';
    final subStatus = client['subscription_status'] as String?;
    final accountStatus = client['status'] as String? ?? '';

    // Account suspension overrides subscription status badge.
    final displayStatus =
        accountStatus == 'suspended' ? 'suspended' : (subStatus ?? 'none');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(displayStatus).withOpacity(0.15),
          child: Icon(
            Icons.person,
            color: _statusColor(displayStatus),
          ),
        ),
        title: Text(fullName),
        subtitle: Text(
          email,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(status: displayStatus),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'active' => Colors.green,
        'trial' => Colors.blue,
        'expired' || 'cancelled' => Colors.red,
        'suspended' => Colors.grey,
        _ => Colors.grey,
      };
}

// ---------------------------------------------------------------------------
// Status badge chip
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Activo', Colors.green),
      'trial' => ('Trial', Colors.blue),
      'expired' => ('Expirado', Colors.red),
      'cancelled' => ('Cancelado', Colors.red),
      'suspended' => ('Suspendido', Colors.grey),
      _ => ('—', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      child: Text('No se encontraron clientes.'),
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
