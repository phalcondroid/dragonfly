class GenericBuilderClass<T> {
  final T Function() creator;

  GenericBuilderClass(this.creator);

  T createInstance() {
    return creator();
  }
}
