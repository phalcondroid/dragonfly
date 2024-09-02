typedef LocatorItemType<T> = Map<String, T>;

class ServiceLocator {
  final LocatorItemType services = {};

  void set<T>(String service, T dependency) {
    services[service] = dependency;
  }

  T get<T>(String service) {
    return services[service] as T;
  }
}
