//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum VideoStatus {
      @JsonValue(r'ingested')
      ingested(r'ingested'),
      @JsonValue(r'processing')
      processing(r'processing'),
      @JsonValue(r'ready')
      ready(r'ready'),
      @JsonValue(r'error')
      error(r'error');

  const VideoStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
