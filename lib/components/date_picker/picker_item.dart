import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget pickerItem(String value, String suffix, bool isSelected) {
  final Color textColor = isSelected ? const Color(0xFF42A5F5) : Colors.black54;
  final FontWeight fontWeight =
      isSelected ? FontWeight.bold : FontWeight.normal;
  final double fontSize = isSelected ? 24 : 18;

  return Center(
    child: RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: fontSize,
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
          TextSpan(
            text: suffix,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
