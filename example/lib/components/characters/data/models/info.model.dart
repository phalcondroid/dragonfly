// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'info.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$Info implements FactoryModelWatcher, Info {
  _$Info({
    required this.count,
    required this.pages,
    required this.next,
    required this.prev,
  });

  factory _$Info.fromJson(Map<String, Object?> json) {
    return _$Info(
        count: JsonDatatypeMapper.mapForGeneric<int>(json, 'count',
            defaultValue: null, mustWithDefault: false),
        pages: JsonDatatypeMapper.mapForGeneric<int>(json, 'pages',
            defaultValue: null, mustWithDefault: false),
        next: JsonDatatypeMapper.mapForGeneric<String>(json, 'next',
            defaultValue: null, mustWithDefault: false),
        prev: JsonDatatypeMapper.mapForGeneric<String?>(json, 'prev',
            defaultValue: null, mustWithDefault: false));
  }

  @override
  final int count;

  @override
  final int pages;

  @override
  final String next;

  @override
  final String? prev;
}

abstract class _$InfoContract {
  int get count;

  int get pages;

  String get next;

  String? get prev;
}
