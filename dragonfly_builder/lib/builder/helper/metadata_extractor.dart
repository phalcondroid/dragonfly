import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import '../types/enums/http_annotations.dart';
import 'package:dragonfly_annotations/dragonfly_annotations.dart';
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

  static dynamic castResultByType(DartObject? object) {
    if (object!.type!.isDartCoreString) {
      return object.toStringValue();
    }
    if (object.type!.isDartCoreInt) {
      return object.toIntValue();
    }
    if (object.type!.isDartCoreDouble) {
      return object.toDoubleValue();
    }
    if (object.type!.isDartCoreDouble) {
      return object.toBoolValue();
    }
    if (object.type!.isDartCoreMap) {
      return object.toMapValue() as Map<dynamic, dynamic>;
    }
    if (object.type!.isDartCoreList) {
      return object.toListValue();
    }
  }

  static dynamic getFromElement(Element element, Type type, String field) {
    Iterable<DartObject> annotations =
        TypeChecker.fromRuntime(type).annotationsOf(element);
    for (DartObject item in annotations) {
      return castResultByType(item.getField(field));
    }
  }

  static HttpAnnotations getMethodType(MethodElement element) {
    for (final ElementAnnotation item in element.metadata) {
      if (item.toString().contains("@Get")) {
        return HttpAnnotations.get;
      }
      if (item.toString().contains("@Post")) {
        return HttpAnnotations.post;
      }
      if (item.toString().contains("@Delete")) {
        return HttpAnnotations.delete;
      }
      if (item.toString().contains("@Patch")) {
        return HttpAnnotations.patch;
      }
      if (item.toString().contains("@Put")) {
        return HttpAnnotations.put;
      }
    }
    return HttpAnnotations.unknow;
  }

  static String getGenericClassName(String name) {
    String methodClass = "";
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

  static dynamic getAnnotationMethodField(MethodElement element, String field) {
    final HttpAnnotations type = getMethodType(element);
    Type? method = switch (type) {
      HttpAnnotations.get => Get,
      HttpAnnotations.post => Post,
      HttpAnnotations.patch => Patch,
      HttpAnnotations.put => Put,
      HttpAnnotations.delete => Delete,
      _ => null
    };

    if (method is Type) {
      return MedatadaExtractor.getFromElement(element, method, field);
    }
    return "";
  }

  static String checkContentOfList(String input) {
    RegExp regExp = RegExp(r'<(.*?)>');
    Match? match = regExp.firstMatch(input);
    if (match != null) {
      return match.group(1) ?? "dynamic";
    }
    return "dynamic";
  }

  static String getContentOfTag(String input) {
    RegExp regExp = RegExp(r'<(.*?)>');
    Match? match = regExp.firstMatch(input);
    if (match != null) {
      return match.group(1) ?? "dynamic";
    }
    return "dynamic";
  }
}
