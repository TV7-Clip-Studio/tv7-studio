// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum ClipStatus {
  @JsonValue(r'rendering')
  rendering(r'rendering'),
  @JsonValue(r'ready')
  ready(r'ready'),
  @JsonValue(r'published_partial')
  publishedPartial(r'published_partial'),
  @JsonValue(r'published_all')
  publishedAll(r'published_all'),
  @JsonValue(r'error')
  error(r'error');

  const ClipStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
