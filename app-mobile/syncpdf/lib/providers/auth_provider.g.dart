// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentUserHash() => r'3eaaf658c4f09061cc7ce0367efecdd4c0a574a6';

/// Exposes the currently authenticated [User] or null.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<User?>;
String _$currentSubscriptionHash() =>
    r'9e2d351b47142b315234cfabe9a10fc585b74209';

/// Exposes the current user's [Subscription] or null.
///
/// Copied from [currentSubscription].
@ProviderFor(currentSubscription)
final currentSubscriptionProvider = AutoDisposeProvider<Subscription?>.internal(
  currentSubscription,
  name: r'currentSubscriptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSubscriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentSubscriptionRef = AutoDisposeProviderRef<Subscription?>;
String _$authIsLoadingHash() => r'da25ad84276ccb6da61572d2daee5132b1e54c25';

/// True only while the auth state is being determined at startup.
///
/// Copied from [authIsLoading].
@ProviderFor(authIsLoading)
final authIsLoadingProvider = AutoDisposeProvider<bool>.internal(
  authIsLoading,
  name: r'authIsLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authIsLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthIsLoadingRef = AutoDisposeProviderRef<bool>;
String _$authNotifierHash() => r'00c36defc182409c46f96f2215725086d86b64da';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider =
    AutoDisposeNotifierProvider<AuthNotifier, AuthState>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
