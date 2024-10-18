class ReturnHelper {
  String getTypeFromReturn(String name) {
    return name
        .replaceAll("List", "")
        .replaceAll("Future", "")
        .replaceAll(">", "")
        .replaceAll("<", "");
  }

  bool isReturnList(String name) {
    return name.contains("List<");
  }
}
