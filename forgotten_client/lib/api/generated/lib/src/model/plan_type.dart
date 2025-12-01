// @dart=3.4
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

enum PlanType {
  @JsonValue(r'trial')
  trial(r'trial'),
  @JsonValue(r'core')
  core(r'core'),
  @JsonValue(r'pro')
  pro(r'pro');

  const PlanType(this.value);

  final String value;

  @override
  String toString() => value;
}
