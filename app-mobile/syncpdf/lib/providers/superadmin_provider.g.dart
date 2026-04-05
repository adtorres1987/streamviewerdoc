// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'superadmin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$metricsHash() => r'a954f9edc906040840ebbe055388832b2ff42c07';

/// See also [metrics].
@ProviderFor(metrics)
final metricsProvider = AutoDisposeFutureProvider<Metrics>.internal(
  metrics,
  name: r'metricsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$metricsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MetricsRef = AutoDisposeFutureProviderRef<Metrics>;
String _$adminsHash() => r'22ed5ec21ea7d03ffc1574aa0a5ed7e96cbedde4';

/// See also [Admins].
@ProviderFor(Admins)
final adminsProvider =
    AutoDisposeAsyncNotifierProvider<Admins, List<AdminUser>>.internal(
  Admins.new,
  name: r'adminsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adminsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Admins = AutoDisposeAsyncNotifier<List<AdminUser>>;
String _$settingsHash() => r'a559b0c758bd871c994ea8907669a60b6a97eb75';

/// See also [Settings].
@ProviderFor(Settings)
final settingsProvider =
    AutoDisposeAsyncNotifierProvider<Settings, GlobalSettings>.internal(
  Settings.new,
  name: r'settingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Settings = AutoDisposeAsyncNotifier<GlobalSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
