import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:dragonfly/core/builder/helper/metadata_extractor.dart';

class ModelVisitor extends SimpleElementVisitor<void> {
  late String className;
  final fields = <String, dynamic>{};
  final Map<String, dynamic> metaData = {};
  final Map<String, Map<String, dynamic>> methods = {};

  @override
  void visitConstructorElement(ConstructorElement element) {
    final elementReturnType = element.type.returnType.toString();
    className = elementReturnType.replaceFirst('*', '');
  }

  @override
  void visitFieldElement(FieldElement element) {
    final elementType = element.type.toString();
    fields[element.name] = elementType.replaceFirst('*', '');
    metaData[element.name] = element.metadata;
  }

  @override
  void visitClassElement(ClassElement classElement) {}

  @override
  void visitMethodElement(MethodElement element) {
    String repoUrl = "";
    Map<String, Map<String, dynamic>> params = {};
    methods[element.name] = {"url": repoUrl};

    try {
      methods[element.name]!["url"] += MedatadaExtractor.getUrlByType(element);
    } catch (e, s) {
      print("Catch #0.1 e: $e => s: $s");
    }

    Map<String, String> headers = {};
    /*
    MedatadaExtractor.getMethodAnnotations(element, Headers s).forEach((el) {
      el.peek('headers')?.listValue.forEach((el3) {
        String key = el3.getField('key')?.toStringValue() ?? "";
        String val = el3.getField("value")?.toStringValue() ?? "";
        if (key.contains("@") && val.isEmpty) {
          String header = key.replaceAll("@", "");
          headers.addAll({"'$header'": "container.getContent('$header')"});
        } else {
          headers.addAll({"'$key'": "'$val'"});
        }
      });
    });
    */

    // print("---> Initial ---->> ${element.name}, params: ${element.parameters.first}");

    try {
      /*
      element.parameters.forEach((paramElement) {
        params[paramElement.name] = {
          "raw": paramElement,
          "name": paramElement.name,
        };

        if (element.metadata.firstOrNull.toString().contains("@Get")) {
          if (paramElement.metadata.firstOrNull.toString().contains("@Where")) {
            if (!params[paramElement.name]!.containsKey("where")) {
              params[paramElement.name]?.addAll({"where": {}});
            }
            params[paramElement.name]?["type"] = 'where';
          }
        }

        if (element.metadata.firstOrNull.toString().contains("@Post")) {
          if (paramElement.metadata.firstOrNull
              .toString()
              .contains("@PostRequestModel")) {
            if (!params[paramElement.name]!.containsKey("postRequestModel")) {
              params[paramElement.name]?.addAll({"postRequestModel": {}});
            }
            params[paramElement.name]?["type"] = 'postRequestModel';
          }
          if (paramElement.metadata.firstOrNull
              .toString()
              .contains("@WorkingFor")) {
            if (!params[paramElement.name]!.containsKey("workingFor")) {
              params[paramElement.name]?.addAll({"workingFor": {}});
            }
            params[paramElement.name]?["workingFor"] =
                '${paramElement.declaration}';
            params[paramElement.name]?["type"] = 'where';
          }
        }

        if (paramElement.metadata.isNotEmpty) {
          if (paramElement.metadata.firstOrNull.toString().contains("@Path")) {
            if (!params[paramElement.name]!.containsKey("path")) {
              params[paramElement.name]?.addAll({"path": "path"});
            }
          }

          if (paramElement.metadata.firstOrNull.toString().contains("@Query")) {
            if (!params[paramElement.name]!.containsKey("query")) {
              params[paramElement.name]?.addAll({"query": {}});
            }
            String queryValue = MedatadaExtractor.getFromElement(
                        paramElement, Query, 'value')
                    .toString()
                    .isNotEmpty
                ? MedatadaExtractor.getFromElement(paramElement, Query, 'value')
                : paramElement.name;
            params[paramElement.name]?["query"]["'$queryValue'"] =
                paramElement.name;
            params[paramElement.name]?["type"] = 'query';
          }

          if (paramElement.metadata.firstOrNull
              .toString()
              .contains("@StorageListener")) {
            if (!params[paramElement.name]!.containsKey("storageListener")) {
              params[paramElement.name]?.addAll({"storageListener": {}});
            }
            params[paramElement.name]?["type"] = 'storageListener';
          }
        }
      });*/
    } catch (e, s) {
      print("Visitor Exception ---->>>>>>: $e, stackTrace: $s");
    }

    methods[element.name]?.addAll({
      "params": params,
      "headers": headers,
      "type": MedatadaExtractor.getMethodType(element),
      "name": element.name,
      "return": element.declaration.returnType.toString(),
    });
  }
}
