// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'info.dart';

// **************************************************************************
// FactoryModelGenerator
// **************************************************************************

class _$Info implements FactoryModelWatcher, Info {
  _$Info({required this.count, required this.pages, this.next, this.prev});

  factory _$Info.fromJson(Map<String, Object?> json) {
    return _$Info(
      count: JsonDatatypeMapper.mapForGeneric<int>(
        json,
        'count',
        defaultValue: null,
        mustWithDefault: false,
      ),
      pages: JsonDatatypeMapper.mapForGeneric<int>(
        json,
        'pages',
        defaultValue: null,
        mustWithDefault: false,
      ),
      next: JsonDatatypeMapper.mapForGeneric<String?>(
        json,
        'next',
        defaultValue: null,
        mustWithDefault: false,
      ),
      prev: JsonDatatypeMapper.mapForGeneric<String?>(
        json,
        'prev',
        defaultValue: null,
        mustWithDefault: false,
      ),
    );
  }

  @override
  final int count;

  @override
  final int pages;

  @override
  final String? next;

  @override
  final String? prev;

  Map<String, dynamic> toJson() {
    return {'count': count, 'pages': pages, 'next': next, 'prev': prev};
  }

  @override
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'count': count,
      'pages': pages,
      'next': next,
      'prev': prev,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Info &&
        other.count == count &&
        other.pages == pages &&
        other.next == next &&
        other.prev == prev;
  }

  @override
  int get hashCode {
    return count.hashCode ^ pages.hashCode ^ next.hashCode ^ prev.hashCode;
  }

  @override
  String toString() {
    return 'Info(count: $count, pages: $pages, next: $next, prev: $prev)';
  }
}

abstract class _$InfoContract {
  int get count;

  int get pages;

  String? get next;

  String? get prev;

  Map<String, dynamic> toJson();
  Map<String, Object?> toMap();
}
