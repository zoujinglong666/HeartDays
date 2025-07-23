import 'package:flutter/material.dart';

class Option<T> {
  final String label;
  final T value;
  final Widget? icon;

  const Option({
    required this.label,
    required this.value,
    this.icon,
  });

  Option.fromJson(Map<String, dynamic> json)
      : this(label: json["label"], value: json["value"]);

  @override
  Map<String, dynamic> toJson() => {"label": label, "value": value};

  @override
  String toString() => 'Option(label: $label, value: $value)';
}