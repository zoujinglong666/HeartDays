import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heart_days/apis/anniversary.dart';
import 'package:intl/intl.dart';

class AnniversaryCard extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleFavorite;
  final Anniversary anniversary;
  const AnniversaryCard({
    super.key,
    this.onTap,
    this.onLongPress,
    this.onToggleFavorite, required this.anniversary,
  });

  @override
  Widget build(BuildContext context) {
    final color = (anniversary.color ?? Colors.black);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(anniversary.date.year, anniversary.date.month, anniversary.date.day);
    final daysDiff = target.difference(today).inDays;

    String dayText;
    String dayLabel;
    double progress;
    const double totalDays = 30.0; // 你可以自定义周期

    if (daysDiff > 0) {
      dayText = daysDiff.toString();
      dayLabel = '还剩';
      progress = (totalDays - daysDiff) / totalDays;
    } else if (daysDiff == 0) {
      dayText = '0';
      dayLabel = '';
      progress = 1.0;
    } else {
      dayText = (-daysDiff).toString();
      dayLabel = '已过';
      progress = 1.0;
    }
    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    progress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [color, color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题区域
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          anniversary.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          dayText,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,

                          ),
                        ),
                        Text(
                          '天',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dayLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 底部日期和描述区域 - 调整高度和位置
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 50, // 固定高度，避免遮挡
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10), // 减少垂直padding
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.white), // 稍微减小图标
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy年MM月dd日').format(anniversary.date),
                          style: const TextStyle(
                            fontSize: 14, // 稍微减小字体
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            anniversary.description,
                            style: const TextStyle(
                              fontSize: 14, // 稍微减小字体
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
