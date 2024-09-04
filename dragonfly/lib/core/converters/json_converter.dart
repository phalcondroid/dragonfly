class JsonConverter {
  Map<String, Object?> toJson(params) {
    return Map.from({});
  }

  T fromJson<T>(T Function() creator) {
    return creator();
  }
}
