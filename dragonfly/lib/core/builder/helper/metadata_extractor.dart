import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

class MedatadaExtractor {
  static TypeChecker typeChecker(Type type) => TypeChecker.fromRuntime(type);

  static Iterable<ConstantReader> getMethodAnnotations(
    MethodElement method,
    Type type,
  ) =>
      typeChecker(type)
          .annotationsOf(method, throwOnUnresolved: false)
          .map(ConstantReader.new);

  static dynamic getFromElement(Element element, Type type, String field) {
    return TypeChecker.fromRuntime(type)
            .annotationsOf(element)
            .first
            .getField(field)
            ?.toStringValue() ??
        '';
  }

  static String getMethodType(MethodElement element) {
    if (element.metadata.first.toString().contains("@DeleteLocalStorage")) {
      return "deleteLocalStorage";
    }
    if (element.metadata.first.toString().contains("@GetLocalStorage")) {
      return "getLocalStorage";
    }
    if (element.metadata.first.toString().contains("@SaveLocalStorage")) {
      return "saveLocalStorage";
    }
    if (element.metadata.first.toString().contains("@PurgeLocalStorage")) {
      return "purgeLocalStorage";
    }
    if (element.metadata.first.toString().contains("@Get")) {
      return "get";
    }
    if (element.metadata.first.toString().contains("@Post")) {
      return "post";
    }
    if (element.metadata.first.toString().contains("@Delete")) {
      return "delete";
    }
    if (element.metadata.first.toString().contains("@Remove")) {
      return "remove";
    }
    return "_no_method";
  }

  static String cleanModelName(String name) {
    if (name.contains("AlvicSingleResponse")) {
      return "AlvicSingleResponse";
    }
    if (name.contains("AlvicListResponse")) {
      return name.replaceAll("Future<", "").replaceAll(">>", ">");
    }
    if (name.contains("AlvicResponse")) {
      return "AlvicResponse";
    }
    return name
        .toString()
        .replaceAll("Future", "")
        .replaceAll("List", "")
        .replaceAll("<", "")
        .replaceAll(">", "")
        .replaceAll("?", "")
        .trim();
  }

  static String getGenericClassName(String name) {
    String methodClass = "";

    if (name.contains("AlvicSingleResponse")) {
      methodClass = "AlvicSingleResponse";
    }
    if (name.contains("AlvicResponse")) {
      methodClass = "AlvicResponse";
    }
    if (methodClass.isEmpty) {
      return "";
    }
    List<String> strList = name.split(methodClass);
    return strList[1]
        .toString()
        .replaceAll("Future", "")
        .replaceAll("List", "")
        .replaceAll("<", "")
        .replaceAll(">", "")
        .replaceAll("?", "")
        .trim();
  }

  static String getGenericListClassName(String name) {
    String methodClass = "";

    if (name.contains("AlvicListResponse")) {
      methodClass = "AlvicListResponse";
    }
    if (name.contains("AlvicResponse")) {
      methodClass = "AlvicResponse";
    }
    if (methodClass.isEmpty) {
      return "";
    }
    List<String> strList = name.split(methodClass);
    return strList[1]
        .toString()
        .replaceAll("Future", "")
        .replaceAll("<", "")
        .replaceAll(">", "")
        .replaceAll("?", "")
        .trim();
  }

  static String getUrlByType(MethodElement element) {
    var type = getMethodType(element);
    if (type == "get") {
      //return MedatadaExtractor.getFromElement(element, Get, 'path');
    }
    if (type == "post") {
      //return MedatadaExtractor.getFromElement(element, Post, 'path');
    }
    if (type == "remove") {
      //return MedatadaExtractor.getFromElement(element, Put, 'path');
    }
    if (type == "delete") {
      //return MedatadaExtractor.getFromElement(element, Delete, 'path');
    }
    return "";
  }
}
