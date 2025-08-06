import 'package:flutter/material.dart';

class NeumorphicTheme {
  // 主背景色
  static const Color background = Color(0xFFF5F5F5);
  
  // 强调色
  static const Color accentColor = Color(0xFF6C63FF);
  
  // 优先级颜色
  static const highPriorityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFF4757),
    ],
  );
  
  static const mediumPriorityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFB74D),
      Color(0xFFFF9800),
    ],
  );
  
  static const lowPriorityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF81C784),
      Color(0xFF4CAF50),
    ],
  );
  
  // 优先级纯色
  static const Color highPriorityColor = Color(0xFFFF4757);
  static const Color mediumPriorityColor = Color(0xFFFF9800);
  static const Color lowPriorityColor = Color(0xFF4CAF50);
  
  // 获取优先级颜色
  static Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return highPriorityColor;
      case 'medium':
        return mediumPriorityColor;
      case 'low':
        return lowPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }
  
  // 获取优先级渐变
  static Gradient getPriorityGradient(String priority) {
    switch (priority) {
      case 'high':
        return highPriorityGradient;
      case 'medium':
        return mediumPriorityGradient;
      case 'low':
        return lowPriorityGradient;
      default:
        return mediumPriorityGradient;
    }
  }
  
  // 动画持续时间
  static const Duration expandDuration = Duration(milliseconds: 200);
  static const Duration dragHighlightDuration = Duration(milliseconds: 150);
  static const Duration slideDuration = Duration(milliseconds: 250);
  
  // 动画曲线
  static const Curve expandCurve = Curves.fastOutSlowIn;
  static const Curve slideCurve = Curves.easeOutBack;
  
  // 滑动阻尼和回弹系数
  static const double slideDamping = 0.6;
  static const double slideRebound = 0.9;
}