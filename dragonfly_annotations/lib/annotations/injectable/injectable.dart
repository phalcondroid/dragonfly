/// Marks a class as injectable for dependency injection.
///
/// Classes annotated with @Injectable will be automatically registered
/// with DragonflyContainer when the generated configuration is called.
///
/// Example:
/// ```dart
/// @Injectable()
/// class MyService {
///   MyService();
/// }
/// ```
class Injectable {
  /// The type to register this class as (interface/abstract class).
  /// If not specified, the class will be registered as itself.
  final Type? as;

  /// Environment names where this dependency should be registered.
  /// If null, it will be registered in all environments.
  final List<String>? env;

  /// Scope name for this dependency.
  /// Dependencies with the same scope can be disposed together.
  final String? scope;

  /// Registration order. Lower numbers are registered first.
  /// Useful for controlling initialization order.
  final int? order;

  const Injectable({
    this.as,
    this.env,
    this.scope,
    this.order,
  });
}

/// Marks a class to be registered as a singleton.
///
/// The instance is created immediately when the configuration is called.
/// Only one instance will exist throughout the app lifecycle.
///
/// Example:
/// ```dart
/// @Singleton()
/// class DatabaseService {
///   DatabaseService();
/// }
/// ```
class Singleton {
  final Type? as;
  final List<String>? env;
  final String? scope;
  final int? order;

  const Singleton({
    this.as,
    this.env,
    this.scope,
    this.order,
  });
}

/// Marks a class to be registered as a lazy singleton.
///
/// The instance is created only when first requested.
/// Only one instance will exist throughout the app lifecycle.
///
/// Example:
/// ```dart
/// @LazySingleton()
/// class CacheService {
///   CacheService();
/// }
/// ```
class LazySingleton {
  final Type? as;
  final List<String>? env;
  final String? scope;
  final int? order;

  const LazySingleton({
    this.as,
    this.env,
    this.scope,
    this.order,
  });
}

/// Marks a class to be registered as a factory.
///
/// A new instance is created each time it's requested.
///
/// Example:
/// ```dart
/// @Factory()
/// class RequestHandler {
///   RequestHandler();
/// }
/// ```
class Factory {
  final Type? as;
  final List<String>? env;
  final String? scope;
  final int? order;

  const Factory({
    this.as,
    this.env,
    this.scope,
    this.order,
  });
}
