class MapperRowHelper {
  int parseToInt(String field, Object? value) {
    try {
      return value as int;
    } catch (e, s) {
      return 0;
      /*throw DragonflyException(
          message:
              "Field '$field' exception trying to convert to int with value $value",
          stackTrace: s);*/
    }
  }

  String parseToString(String field, Object? value) {
    try {
      return value as String;
    } catch (e, s) {
      return "";
      /*throw DragonflyException(
          message:
              "Field '$field' exception trying to convert to string with value $value",
          stackTrace: s);*/
    }
  }

  bool parseToBool(String field, Object? value) {
    try {
      return value as bool;
    } catch (e, s) {
      return false;
      /*throw DragonflyException(
          message:
              "Field '$field' exception trying to convert to boolean with value $value",
          stackTrace: s);*/
    }
  }

  DateTime paseToDateTime(String field, Object? value) {
    try {
      int intVal = parseToInt(field, value);
      if (intVal > 0) {
        return DateTime.fromMillisecondsSinceEpoch(intVal);
      }
      return DateTime.parse(value.toString());
    } catch (e, s) {
      /*throw DragonflyException(
          message:
              "Field '$field' exception trying to convert to boolean with value $value",
          stackTrace: s);*/
    }
    return DateTime.now();
  }
}
