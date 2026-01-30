import 'dart:async';

typedef FactoryFunc<T> = T Function();
typedef FactoryFuncParam<T, P1, P2> = T Function(P1 param1, P2 param2);
typedef FactoryFuncAsync<T> = Future<T> Function();
typedef FactoryFuncParamAsync<T, P1, P2> = Future<T> Function(
    P1 param1, P2 param2);
typedef DisposingFunc<T> = FutureOr<void> Function(T param);
typedef ScopeDisposeFunc = FutureOr<void> Function();

enum DragonflyInjectorType { singleton, factory }

class DragonflyContainer {
  static final DragonflyContainer _instance = DragonflyContainer();
  static DragonflyContainer get instance => _instance;
  static DragonflyContainer get I => _instance;

  final List<Map<_ServiceKey, _ServiceEntry>> _scopes = [];

  DragonflyContainer() {
    _scopes.add({});
  }

  Map<_ServiceKey, _ServiceEntry> get _currentScope => _scopes.last;

  void Function(bool pushed)? onScopeChanged;
  bool allowReassignment = false;

  static void set<T extends Object>(String name, T dependency,
      {DragonflyInjectorType type = DragonflyInjectorType.singleton}) {
    if (type == DragonflyInjectorType.singleton) {
      if (!I.isRegistered<T>(instanceName: name)) {
        I.registerSingleton<T>(dependency, instanceName: name);
      }
    } else {
      I.registerFactory<T>(() => dependency, instanceName: name);
    }
  }

  bool isRegistered<T extends Object>(
      {Object? instance, String? instanceName}) {
    final key = _ServiceKey(T, instanceName);
    for (var scope in _scopes.reversed) {
      if (scope.containsKey(key)) return true;
    }
    return false;
  }

  T registerSingleton<T extends Object>(T instance,
      {String? instanceName, bool? signalsReady, DisposingFunc<T>? dispose}) {
    _register<_ServiceEntry<T>>(
        _ServiceEntry<T>.singleton(instance, dispose: dispose),
        instanceName: instanceName);
    return instance;
  }

  void registerLazySingleton<T extends Object>(T Function() factoryFunc,
      {String? instanceName,
      FutureOr<dynamic> Function(T)? dispose,
      void Function(T)? onCreated,
      bool useWeakReference = false}) {
    _register<_ServiceEntry<T>>(
        _ServiceEntry<T>.lazy(factoryFunc,
            dispose: dispose, onCreated: onCreated),
        instanceName: instanceName);
  }

  void registerFactory<T extends Object>(FactoryFunc<T> factoryFunc,
      {String? instanceName}) {
    _register<_ServiceEntry<T>>(_ServiceEntry<T>.factory(factoryFunc),
        instanceName: instanceName);
  }

  void registerFactoryParam<T extends Object, P1, P2>(
      FactoryFuncParam<T, P1, P2> factoryFunc,
      {String? instanceName}) {
    _register<_ServiceEntry<T>>(_ServiceEntry<T>.factoryParam(factoryFunc),
        instanceName: instanceName);
  }

  void registerSingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    Iterable<Type>? dependsOn,
    bool? signalsReady,
    FutureOr<dynamic> Function(T)? dispose,
    void Function(T)? onCreated,
  }) {
    _register<_ServiceEntry<T>>(
        _ServiceEntry<T>.asyncSingleton(factoryFunc,
            dispose: dispose, onCreated: onCreated),
        instanceName: instanceName);
  }

  void registerFactoryAsync<T extends Object>(FactoryFuncAsync<T> factoryFunc,
      {String? instanceName}) {
    _register<_ServiceEntry<T>>(_ServiceEntry<T>.asyncFactory(factoryFunc),
        instanceName: instanceName);
  }

  void registerFactoryParamAsync<T extends Object, P1, P2>(
      FactoryFuncParamAsync<T, P1?, P2?> factoryFunc,
      {String? instanceName}) {
    _register<_ServiceEntry<T>>(_ServiceEntry<T>.asyncFactoryParam(factoryFunc),
        instanceName: instanceName);
  }

  void registerLazySingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    FutureOr<dynamic> Function(T)? dispose,
    void Function(T)? onCreated,
    bool useWeakReference = false,
  }) {
    _register<_ServiceEntry<T>>(
        _ServiceEntry<T>.asyncLazySingleton(factoryFunc,
            dispose: dispose, onCreated: onCreated),
        instanceName: instanceName);
  }

  void registerSingletonWithDependencies<T extends Object>(
      FactoryFunc<T> factoryFunc,
      {String? instanceName,
      Iterable<Type>? dependsOn,
      bool? signalsReady,
      DisposingFunc<T>? dispose}) {
    registerSingleton<T>(factoryFunc(),
        instanceName: instanceName,
        signalsReady: signalsReady,
        dispose: dispose);
  }

  T get<T extends Object>(
      {String? instanceName, dynamic param1, dynamic param2, Type? type}) {
    final key = _ServiceKey(type ?? T, instanceName);
    for (var scope in _scopes.reversed) {
      if (scope.containsKey(key)) {
        return scope[key]!.get(param1, param2) as T;
      }
    }
    throw Exception(
        "Object of type ${type ?? T} with name ${instanceName} not found");
  }

  T call<T extends Object>(
      {String? instanceName, dynamic param1, dynamic param2, Type? type}) {
    return get<T>(
        instanceName: instanceName, param1: param1, param2: param2, type: type);
  }

  Future<T> getAsync<T extends Object>(
      {String? instanceName,
      dynamic param1,
      dynamic param2,
      Type? type}) async {
    final key = _ServiceKey(type ?? T, instanceName);
    for (var scope in _scopes.reversed) {
      if (scope.containsKey(key)) {
        return scope[key]!.getAsync(param1, param2) as Future<T>;
      }
    }
    throw Exception(
        "Object of type ${type ?? T} with name ${instanceName} not found");
  }

  void _register<E extends _ServiceEntry>(E entry, {String? instanceName}) {
    final key = _ServiceKey(entry.type, instanceName);
    if (!allowReassignment && _currentScope.containsKey(key)) {
      // Allow overriding? GetIt allows it if allowReassignment is true.
      // Here defaults to false.
      // However, to keep it simple, we log or throw?
      // user asked to remove GetIt and implement functionality.
      return;
    }
    _currentScope[key] = entry;
  }

  void pushNewScope(
      {void Function(DragonflyContainer getIt)? init,
      String? scopeName,
      ScopeDisposeFunc? dispose,
      bool? isFinal}) {
    _scopes.add({});
    onScopeChanged?.call(true);
    init?.call(this);
  }

  Future<void> popScope() async {
    if (_scopes.length > 1) {
      final scope = _scopes.removeLast();
      for (var entry in scope.values) {
        await entry.dispose();
      }
      onScopeChanged?.call(false);
    }
  }

  // Method needed for helper
  Future<void> allReady(
      {Duration? timeout, bool ignorePendingAsyncCreation = false}) async {
    // Simplified: we don't track async creation status finely yet
    return Future.value();
  }

  bool allReadySync([bool ignorePendingAsyncCreation = false]) => true;

  Future<void> isReady<T extends Object>(
      {Object? instance,
      String? instanceName,
      Duration? timeout,
      Object? callee}) async {
    return Future.value();
  }
}

class _ServiceKey {
  final Type type;
  final String? name;
  _ServiceKey(this.type, this.name);
  @override
  bool operator ==(Object other) =>
      other is _ServiceKey && other.type == type && other.name == name;
  @override
  int get hashCode => type.hashCode ^ (name?.hashCode ?? 0);
}

class _ServiceEntry<T> {
  final Type type;
  final bool isSingleton;
  final bool isLazy;
  final bool isAsync;
  T? _instance; // For singletons
  Future<T>? _futureInstance; // For async singletons
  dynamic _factory; // Can be FactoryFunc, FactoryFuncParam, etc.
  DisposingFunc<T>? _dispose;
  void Function(T)? _onCreated;

  _ServiceEntry.singleton(T instance, {DisposingFunc<T>? dispose})
      : type = T,
        isSingleton = true,
        isLazy = false,
        isAsync = false,
        _instance = instance,
        _dispose = dispose;

  _ServiceEntry.lazy(T Function() factory,
      {DisposingFunc<T>? dispose, void Function(T)? onCreated})
      : type = T,
        isSingleton = true,
        isLazy = true,
        isAsync = false,
        _factory = factory,
        _dispose = dispose,
        _onCreated = onCreated;

  _ServiceEntry.factory(FactoryFunc<T> factory)
      : type = T,
        isSingleton = false,
        isLazy = false,
        isAsync = false,
        _factory = factory;

  _ServiceEntry.factoryParam(Function factory)
      : type = T,
        isSingleton = false,
        isLazy = false,
        isAsync = false,
        _factory = factory;

  _ServiceEntry.asyncSingleton(Future<T> Function() factory,
      {DisposingFunc<T>? dispose, void Function(T)? onCreated})
      : type = T,
        isSingleton = true,
        isLazy = false,
        isAsync = true,
        _factory = factory,
        _dispose = dispose,
        _onCreated = onCreated {
    // Trigger immediately
    _futureInstance = factory().then((val) {
      _instance = val;
      _onCreated?.call(val);
      return val;
    });
  }

  _ServiceEntry.asyncLazySingleton(Future<T> Function() factory,
      {DisposingFunc<T>? dispose, void Function(T)? onCreated})
      : type = T,
        isSingleton = true,
        isLazy = true,
        isAsync = true,
        _factory = factory,
        _dispose = dispose,
        _onCreated = onCreated;

  _ServiceEntry.asyncFactory(FactoryFuncAsync<T> factory)
      : type = T,
        isSingleton = false,
        isLazy = false,
        isAsync = true,
        _factory = factory;

  _ServiceEntry.asyncFactoryParam(Function factory)
      : type = T,
        isSingleton = false,
        isLazy = false,
        isAsync = true,
        _factory = factory;

  dynamic get(dynamic p1, dynamic p2) {
    if (isSingleton) {
      if (isAsync) {
        throw Exception("Cannot use get() for async singleton, use getAsync()");
      }
      if (isLazy && _instance == null) {
        _instance = (_factory as FactoryFunc<T>)();
        _onCreated?.call(_instance as T);
      }
      return _instance!;
    }
    // Factory
    if (_factory is FactoryFunc<T>) {
      return (_factory as FactoryFunc<T>)();
    } else if (_factory is FactoryFuncParam<T, dynamic, dynamic>) {
      return (_factory as FactoryFuncParam<T, dynamic, dynamic>)(p1, p2);
    }
    throw Exception("Unknown factory type");
  }

  Future<dynamic> getAsync(dynamic p1, dynamic p2) async {
    if (isSingleton) {
      if (isAsync) {
        if (isLazy && _futureInstance == null) {
          _futureInstance = (_factory as Future<T> Function())().then((val) {
            _instance = val;
            _onCreated?.call(val);
            return val;
          });
        }
        return _futureInstance!;
      }
      // Non-async singleton, return instance
      return get(p1, p2);
    }
    // Async Factory
    if (_factory is FactoryFuncAsync<T>) {
      return (_factory as FactoryFuncAsync<T>)();
    } else if (_factory is FactoryFuncParamAsync<T, dynamic, dynamic>) {
      return (_factory as FactoryFuncParamAsync<T, dynamic, dynamic>)(p1, p2);
    }
    // Non-async Factory called via getAsync?
    return get(p1, p2);
  }

  Future<void> dispose() async {
    if (_instance != null && _dispose != null) {
      await _dispose!(_instance as T);
    }
  }
}
