//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum PublishJobStatus {
      @JsonValue(r'pending')
      pending(r'pending'),
      @JsonValue(r'queued')
      queued(r'queued'),
      @JsonValue(r'publishing')
      publishing(r'publishing'),
      @JsonValue(r'partial')
      partial(r'partial'),
      @JsonValue(r'complete')
      complete(r'complete'),
      @JsonValue(r'failed')
      failed(r'failed');

  const PublishJobStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
