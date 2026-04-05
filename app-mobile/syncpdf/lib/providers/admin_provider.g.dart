// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientDetailHash() => r'fd234642d564fc145f600973760160702c61b067';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [clientDetail].
@ProviderFor(clientDetail)
const clientDetailProvider = ClientDetailFamily();

/// See also [clientDetail].
class ClientDetailFamily extends Family<AsyncValue<ClientDetail>> {
  /// See also [clientDetail].
  const ClientDetailFamily();

  /// See also [clientDetail].
  ClientDetailProvider call(
    String id,
  ) {
    return ClientDetailProvider(
      id,
    );
  }

  @override
  ClientDetailProvider getProviderOverride(
    covariant ClientDetailProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'clientDetailProvider';
}

/// See also [clientDetail].
class ClientDetailProvider extends AutoDisposeFutureProvider<ClientDetail> {
  /// See also [clientDetail].
  ClientDetailProvider(
    String id,
  ) : this._internal(
          (ref) => clientDetail(
            ref as ClientDetailRef,
            id,
          ),
          from: clientDetailProvider,
          name: r'clientDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$clientDetailHash,
          dependencies: ClientDetailFamily._dependencies,
          allTransitiveDependencies:
              ClientDetailFamily._allTransitiveDependencies,
          id: id,
        );

  ClientDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<ClientDetail> Function(ClientDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ClientDetailProvider._internal(
        (ref) => create(ref as ClientDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ClientDetail> createElement() {
    return _ClientDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClientDetailRef on AutoDisposeFutureProviderRef<ClientDetail> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ClientDetailProviderElement
    extends AutoDisposeFutureProviderElement<ClientDetail>
    with ClientDetailRef {
  _ClientDetailProviderElement(super.provider);

  @override
  String get id => (origin as ClientDetailProvider).id;
}

String _$clientsHash() => r'3e176e556b3ab38a1ab284bfe242d3cd7e01dacb';

abstract class _$Clients
    extends BuildlessAutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  late final String? q;

  FutureOr<List<Map<String, dynamic>>> build({
    String? q,
  });
}

/// See also [Clients].
@ProviderFor(Clients)
const clientsProvider = ClientsFamily();

/// See also [Clients].
class ClientsFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [Clients].
  const ClientsFamily();

  /// See also [Clients].
  ClientsProvider call({
    String? q,
  }) {
    return ClientsProvider(
      q: q,
    );
  }

  @override
  ClientsProvider getProviderOverride(
    covariant ClientsProvider provider,
  ) {
    return call(
      q: provider.q,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'clientsProvider';
}

/// See also [Clients].
class ClientsProvider extends AutoDisposeAsyncNotifierProviderImpl<Clients,
    List<Map<String, dynamic>>> {
  /// See also [Clients].
  ClientsProvider({
    String? q,
  }) : this._internal(
          () => Clients()..q = q,
          from: clientsProvider,
          name: r'clientsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$clientsHash,
          dependencies: ClientsFamily._dependencies,
          allTransitiveDependencies: ClientsFamily._allTransitiveDependencies,
          q: q,
        );

  ClientsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.q,
  }) : super.internal();

  final String? q;

  @override
  FutureOr<List<Map<String, dynamic>>> runNotifierBuild(
    covariant Clients notifier,
  ) {
    return notifier.build(
      q: q,
    );
  }

  @override
  Override overrideWith(Clients Function() create) {
    return ProviderOverride(
      origin: this,
      override: ClientsProvider._internal(
        () => create()..q = q,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        q: q,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Clients, List<Map<String, dynamic>>>
      createElement() {
    return _ClientsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientsProvider && other.q == q;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, q.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ClientsRef
    on AutoDisposeAsyncNotifierProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `q` of this provider.
  String? get q;
}

class _ClientsProviderElement extends AutoDisposeAsyncNotifierProviderElement<
    Clients, List<Map<String, dynamic>>> with ClientsRef {
  _ClientsProviderElement(super.provider);

  @override
  String? get q => (origin as ClientsProvider).q;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
