import 'dart:async';

import 'package:get_it/get_it.dart';

typedef DiItemType<T> = Map<String, T>;

enum DragonflyInjectorType { singleton, factory }

class DragonflyContainer implements GetIt {
  static void set<T extends Object>(String name, T dependency,
      {DragonflyInjectorType type = DragonflyInjectorType.singleton}) {
    if (type == DragonflyInjectorType.singleton) {
      if (!GetIt.I.isRegistered<T>(instanceName: name)) {
        GetIt.I.registerSingleton<T>(dependency, instanceName: name);
      }
    }
  }

  @override
  void Function(bool pushed)? onScopeChanged = GetIt.I.onScopeChanged;

  @override
  bool allowReassignment = false;

  @override
  bool skipDoubleRegistration = false;

  @override
  void enableRegisteringMultipleInstancesOfOneType() {
    allowRegisterMultipleImplementationsOfoneType = true;
  }

  @override
  bool allowRegisterMultipleImplementationsOfoneType = false;

  @override
  Future<void> allReady(
          {Duration? timeout, bool ignorePendingAsyncCreation = false}) =>
      GetIt.I.allReady(
          timeout: timeout,
          ignorePendingAsyncCreation: ignorePendingAsyncCreation);

  @override
  bool allReadySync([bool ignorePendingAsyncCreation = false]) =>
      GetIt.I.allReadySync(ignorePendingAsyncCreation);

  @override
  T call<T extends Object>(
          {String? instanceName, param1, param2, Type? type}) =>
      GetIt.I.call<T>(
          instanceName: instanceName,
          param1: param1,
          param2: param2,
          type: type);

  @override
  void changeTypeInstanceName<T extends Object>(
          {String? instanceName,
          required String newInstanceName,
          T? instance}) =>
      GetIt.I.changeTypeInstanceName(
          newInstanceName: newInstanceName,
          instance: instance,
          instanceName: instanceName);

  @override
  bool checkLazySingletonInstanceExists<T extends Object>(
          {String? instanceName}) =>
      GetIt.I.checkLazySingletonInstanceExists(instanceName: instanceName);

  @override
  String? get currentScopeName => GetIt.I.currentScopeName;

  @override
  Future<void> dropScope(String scopeName) => GetIt.I.dropScope(scopeName);

  @override
  Iterable<T> getAll<T extends Object>(
          {dynamic param1,
          dynamic param2,
          bool fromAllScopes = false,
          String? onlyInScope}) =>
      GetIt.I.getAll(
          param1: param1,
          param2: param2,
          fromAllScopes: fromAllScopes,
          onlyInScope: onlyInScope);

  @override
  Future<Iterable<T>> getAllAsync<T extends Object>({
    dynamic param1,
    dynamic param2,
    bool fromAllScopes = false,
    String? onlyInScope,
  }) =>
      GetIt.I.getAllAsync(
          param1: param1,
          param2: param2,
          fromAllScopes: fromAllScopes,
          onlyInScope: onlyInScope);

  @override
  Future<T> getAsync<T extends Object>(
          {String? instanceName, param1, param2, Type? type}) =>
      GetIt.I
          .getAsync(instanceName: instanceName, param1: param1, param2: param2);

  @override
  bool hasScope(String scopeName) => GetIt.I.hasScope(scopeName);

  @override
  Future<void> isReady<T extends Object>(
          {Object? instance,
          String? instanceName,
          Duration? timeout,
          Object? callee}) =>
      GetIt.I.isReady(
          instance: instance,
          instanceName: instanceName,
          timeout: timeout,
          callee: callee);

  @override
  bool isReadySync<T extends Object>(
          {Object? instance, String? instanceName}) =>
      GetIt.I.isReadySync(instance: instance, instanceName: instanceName);

  @override
  bool isRegistered<T extends Object>({
    Object? instance,
    String? instanceName,
    Type? type,
  }) =>
      GetIt.I.isRegistered(
          instance: instance, instanceName: instanceName, type: type);

  @override
  Future<void> popScope() => GetIt.I.popScope();

  @override
  Future<bool> popScopesTill(String name, {bool inclusive = true}) =>
      GetIt.I.popScopesTill(name, inclusive: inclusive);

  @override
  void pushNewScope(
          {void Function(DragonflyContainer getIt)? init,
          String? scopeName,
          ScopeDisposeFunc? dispose,
          bool? isFinal}) =>
      GetIt.I.pushNewScope(
          init: (GetIt getIt) {},
          scopeName: scopeName,
          dispose: dispose,
          isFinal: isFinal ?? false);

  GetIt getInstance() {
    return GetIt.I;
  }

  @override
  Future<void> pushNewScopeAsync(
          {Future<void> Function(GetIt getIt)? init,
          String? scopeName,
          ScopeDisposeFunc? dispose}) =>
      GetIt.I.pushNewScopeAsync(
          init: init, scopeName: scopeName, dispose: dispose);

  @override
  void registerCachedFactory<T extends Object>(FactoryFunc<T> factoryFunc,
          {String? instanceName}) =>
      GetIt.I.registerCachedFactory(factoryFunc, instanceName: instanceName);

  @override
  void registerCachedFactoryAsync<T extends Object>(
          Future<T> Function() factoryFunc,
          {String? instanceName}) =>
      GetIt.I
          .registerCachedFactoryAsync(factoryFunc, instanceName: instanceName);

  @override
  void registerCachedFactoryParam<T extends Object, P1, P2>(
          FactoryFuncParam<T, P1, P2> factoryFunc,
          {String? instanceName}) =>
      GetIt.I
          .registerCachedFactoryParam(factoryFunc, instanceName: instanceName);

  @override
  void registerCachedFactoryParamAsync<T extends Object, P1, P2>(
      Future<T> Function(P1?, P2?) factoryFunc,
      {String? instanceName}) {
    return GetIt.I.registerCachedFactoryParamAsync(factoryFunc,
        instanceName: instanceName);
  }

  @override
  void registerFactory<T extends Object>(FactoryFunc<T> factoryFunc,
          {String? instanceName}) =>
      GetIt.I.registerFactory(factoryFunc, instanceName: instanceName);

  @override
  void registerFactoryAsync<T extends Object>(FactoryFuncAsync<T> factoryFunc,
          {String? instanceName}) =>
      GetIt.I.registerFactoryAsync(factoryFunc, instanceName: instanceName);

  @override
  void registerFactoryParam<T extends Object, P1, P2>(
          FactoryFuncParam<T, P1, P2> factoryFunc,
          {String? instanceName}) =>
      GetIt.I.registerFactoryParam(factoryFunc, instanceName: instanceName);

  @override
  void registerFactoryParamAsync<T extends Object, P1, P2>(
          FactoryFuncParamAsync<T, P1?, P2?> factoryFunc,
          {String? instanceName}) =>
      GetIt.I
          .registerFactoryParamAsync(factoryFunc, instanceName: instanceName);

  @override
  void registerLazySingleton<T extends Object>(
    T Function() factoryFunc, {
    String? instanceName,
    FutureOr<dynamic> Function(T)? dispose,
    void Function(T)? onCreated,
    bool useWeakReference = false,
  }) =>
      GetIt.I.registerLazySingleton(factoryFunc,
          instanceName: instanceName,
          dispose: dispose,
          useWeakReference: useWeakReference,
          onCreated: onCreated);

  @override
  void registerLazySingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    FutureOr<dynamic> Function(T)? dispose,
    void Function(T)? onCreated,
    bool useWeakReference = false,
  }) =>
      GetIt.I.registerLazySingletonAsync(factoryFunc,
          instanceName: instanceName,
          dispose: dispose,
          useWeakReference: useWeakReference,
          onCreated: onCreated);

  @override
  T registerSingleton<T extends Object>(T instance,
          {String? instanceName,
          bool? signalsReady,
          DisposingFunc<T>? dispose}) =>
      GetIt.I.registerSingleton(instance,
          instanceName: instanceName,
          signalsReady: signalsReady,
          dispose: dispose);

  @override
  void registerSingletonAsync<T extends Object>(
    Future<T> Function() factoryFunc, {
    String? instanceName,
    Iterable<Type>? dependsOn,
    bool? signalsReady,
    FutureOr<dynamic> Function(T)? dispose,
    void Function(T)? onCreated,
  }) =>
      GetIt.I.registerSingletonAsync(factoryFunc,
          instanceName: instanceName,
          dependsOn: dependsOn,
          signalsReady: signalsReady,
          dispose: dispose);

  @override
  T registerSingletonIfAbsent<T extends Object>(T Function() factoryFunc,
          {String? instanceName, DisposingFunc<T>? dispose}) =>
      GetIt.I.registerSingletonIfAbsent(factoryFunc,
          instanceName: instanceName, dispose: dispose);

  @override
  void registerSingletonWithDependencies<T extends Object>(
          FactoryFunc<T> factoryFunc,
          {String? instanceName,
          Iterable<Type>? dependsOn,
          bool? signalsReady,
          DisposingFunc<T>? dispose}) =>
      GetIt.I.registerSingletonWithDependencies(factoryFunc,
          instanceName: instanceName,
          dependsOn: dependsOn,
          signalsReady: signalsReady,
          dispose: dispose);

  @override
  void releaseInstance(Object instance) => GetIt.I.releaseInstance(instance);

  @override
  Future<void> reset({bool dispose = true}) => GetIt.I.reset(dispose: dispose);

  @override
  FutureOr resetLazySingleton<T extends Object>(
          {T? instance,
          String? instanceName,
          FutureOr Function(T p1)? disposingFunction}) =>
      GetIt.I.resetLazySingleton(
          instance: instance,
          instanceName: instanceName,
          disposingFunction: disposingFunction);

  @override
  Future<void> resetScope({bool dispose = true}) =>
      GetIt.I.resetScope(dispose: dispose);

  @override
  void signalReady(Object? instance) => GetIt.I.signalReady(instance);

  @override
  FutureOr unregister<T extends Object>(
          {Object? instance,
          String? instanceName,
          FutureOr Function(T p1)? disposingFunction,
          bool ignoreReferenceCount = false}) =>
      GetIt.I.unregister(
          instance: instance,
          instanceName: instanceName,
          disposingFunction: disposingFunction,
          ignoreReferenceCount: ignoreReferenceCount);

  @override
  T get<T extends Object>({param1, param2, String? instanceName, Type? type}) =>
      GetIt.I.get(
          param1: param1,
          param2: param2,
          instanceName: instanceName,
          type: type);

  @override
  ObjectRegistration<Object>? findFirstObjectRegistration<T extends Object>(
      {Object? instance, String? instanceName}) {
    return GetIt.I.findFirstObjectRegistration(
        instance: instance, instanceName: instanceName);
  }

  @override
  T? maybeGet<T extends Object>(
      {param1, param2, String? instanceName, Type? type}) {
    return GetIt.I.maybeGet(
        param1: param1, param2: param2, instanceName: instanceName, type: type);
  }

  @override
  List<T> findAll<T extends Object>({
    bool includeSubtypes = true,
    bool inAllScopes = false,
    String? onlyInScope,
    bool includeMatchedByRegistrationType = true,
    bool includeMatchedByInstance = true,
    bool instantiateLazySingletons = false,
    bool callFactories = false,
  }) {
    return GetIt.I.findAll(
        includeSubtypes: includeSubtypes,
        inAllScopes: inAllScopes,
        onlyInScope: onlyInScope,
        includeMatchedByRegistrationType: includeMatchedByRegistrationType,
        includeMatchedByInstance: includeMatchedByInstance,
        instantiateLazySingletons: instantiateLazySingletons,
        callFactories: callFactories);
  }

  @override
  Future<void> resetLazySingletons(
      {bool dispose = true, bool inAllScopes = false, String? onlyInScope}) {
    return GetIt.I.resetLazySingletons(
        dispose: dispose, inAllScopes: inAllScopes, onlyInScope: onlyInScope);
  }
}
