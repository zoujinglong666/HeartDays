import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';

class SolarTermCard extends StatelessWidget {
  final DateTime today;
  final String weatherDesc;
  final IconData weatherIcon;

  const SolarTermCard({
    super.key,
    required this.today,
    this.weatherDesc = '晴',
    this.weatherIcon = Icons.wb_sunny,
  });

  @override
  Widget build(BuildContext context) {
    final lunar = Lunar.fromDate(today);
    final solarTerm = lunar.getJieQi();
    final solarTermDate = lunar.getJieQiTable()[solarTerm];

    final nextTerm = lunar.getNextJieQi();
    final nextTermDate = lunar.getJieQiTable()[nextTerm];

    final seasonColor = _getSeasonColors(solarTerm);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: seasonColor,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: seasonColor.last.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(weatherIcon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Text(weatherDesc,
                  style: const TextStyle(fontSize: 16, color: Colors.white))
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '当前节气：$solarTerm',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '下一个：$nextTerm（${DateFormat('M月d日').format(nextTermDate as DateTime)}）',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            '农历：${lunar.toString()}（${lunar.getDayZhi()}年 ${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}）',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          )
        ],
      ),
    );
  }

  List<Color> _getSeasonColors(String solarTerm) {
    final spring = ['立春', '雨水', '惊蛰', '春分', '清明', '谷雨'];
    final summer = ['立夏', '小满', '芒种', '夏至', '小暑', '大暑'];
    final autumn = ['立秋', '处暑', '白露', '秋分', '寒露', '霜降'];
    final winter = ['立冬', '小雪', '大雪', '冬至', '小寒', '大寒'];

    if (spring.contains(solarTerm)) {
      return [Color(0xFFFFEBEE), Color(0xFFF8BBD0)];
    } else if (summer.contains(solarTerm)) {
      return [Color(0xFFFFF3E0), Color(0xFFFFB74D)];
    } else if (autumn.contains(solarTerm)) {
      return [Color(0xFFFFFDE7), Color(0xFFFFF176)];
    } else if (winter.contains(solarTerm)) {
      return [Color(0xFFE3F2FD), Color(0xFF90CAF9)];
    } else {
      return [Colors.pink.shade100, Colors.pink.shade200];
    }
  }
}
