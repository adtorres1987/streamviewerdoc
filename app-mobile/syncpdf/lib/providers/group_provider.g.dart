// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupHash() => r'5ebabcad0af0040d46953543d5d70c46324e5a4c';

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

/// See also [group].
@ProviderFor(group)
const groupProvider = GroupFamily();

/// See also [group].
class GroupFamily extends Family<AsyncValue<Group>> {
  /// See also [group].
  const GroupFamily();

  /// See also [group].
  GroupProvider call(
    String id,
  ) {
    return GroupProvider(
      id,
    );
  }

  @override
  GroupProvider getProviderOverride(
    covariant GroupProvider provider,
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
  String? get name => r'groupProvider';
}

/// See also [group].
class GroupProvider extends AutoDisposeFutureProvider<Group> {
  /// See also [group].
  GroupProvider(
    String id,
  ) : this._internal(
          (ref) => group(
            ref as GroupRef,
            id,
          ),
          from: groupProvider,
          name: r'groupProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupHash,
          dependencies: GroupFamily._dependencies,
          allTransitiveDependencies: GroupFamily._allTransitiveDependencies,
          id: id,
        );

  GroupProvider._internal(
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
    FutureOr<Group> Function(GroupRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupProvider._internal(
        (ref) => create(ref as GroupRef),
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
  AutoDisposeFutureProviderElement<Group> createElement() {
    return _GroupProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupProvider && other.id == id;
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
mixin GroupRef on AutoDisposeFutureProviderRef<Group> {
  /// The parameter `id` of this provider.
  String get id;
}

class _GroupProviderElement extends AutoDisposeFutureProviderElement<Group>
    with GroupRef {
  _GroupProviderElement(super.provider);

  @override
  String get id => (origin as GroupProvider).id;
}

String _$groupsHash() => r'1fd3dcd9b675b22000daf6d99127bd10efa82e9d';

/// See also [Groups].
@ProviderFor(Groups)
final groupsProvider =
    AutoDisposeAsyncNotifierProvider<Groups, List<Group>>.internal(
  Groups.new,
  name: r'groupsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Groups = AutoDisposeAsyncNotifier<List<Group>>;
String _$pendingInvitationsHash() =>
    r'992d84179dfb19048e0200d1ca422a3d746dadbb';

/// See also [PendingInvitations].
@ProviderFor(PendingInvitations)
final pendingInvitationsProvider = AutoDisposeAsyncNotifierProvider<
    PendingInvitations, List<PendingInvitation>>.internal(
  PendingInvitations.new,
  name: r'pendingInvitationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingInvitationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingInvitations
    = AutoDisposeAsyncNotifier<List<PendingInvitation>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
