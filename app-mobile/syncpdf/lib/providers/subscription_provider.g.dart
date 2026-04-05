// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionHash() => r'06dfd6e3aa959fb0ee848942259228c73e681430';

/// See also [subscription].
@ProviderFor(subscription)
final subscriptionProvider = AutoDisposeFutureProvider<Subscription>.internal(
  subscription,
  name: r'subscriptionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$subscriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SubscriptionRef = AutoDisposeFutureProviderRef<Subscription>;
String _$isSubscriptionActiveHash() =>
    r'466ed58b337a79740d66fda9c3db0702f3fc2d8f';

/// True when the user has an active trial or paid subscription.
/// Returns false if the subscription hasn't loaded yet or has no value.
///
/// Copied from [isSubscriptionActive].
@ProviderFor(isSubscriptionActive)
final isSubscriptionActiveProvider = AutoDisposeProvider<bool>.internal(
  isSubscriptionActive,
  name: r'isSubscriptionActiveProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSubscriptionActiveHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSubscriptionActiveRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
