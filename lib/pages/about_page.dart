import 'package:flutter/material.dart';
import 'package:heart_days/components/app_multi_picker/app_multi_picker.dart';
import 'package:heart_days/components/app_picker/app_picker.dart';
import 'package:heart_days/pages/mqtt_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF5C6BC0);
    const Color backgroundColor = Color(0xFFF8F9FA);

    final List<Map<String, String>> highlights = [
      {'title': '纪念日提醒', 'description': '每一个特别的日子，我们都替你牢牢记住，温暖提示，不再错过。'},
      {'title': '心愿记录', 'description': '写下你们的小心愿，让彼此共同期待与实现。'},
      {'title': '照片时光轴', 'description': '用相册记录点滴回忆，时光流转，爱不褪色。'},
      {'title': '节日关怀', 'description': '内置中国传统节日提醒，节日情感不缺席。'},
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('关于我们'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App 标志与标题
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    'lib/assets/images/icon.png',
                    fit: BoxFit.contain,
                  ),
                  // CircleAvatar(
                  //   radius: 40,
                  //   backgroundColor: Colors.white,
                  //   child: const Text(
                  //     '💖',
                  //     style: TextStyle(fontSize: 32),
                  //   ),
                  // ),
                  const SizedBox(height: 16),
                  const Text(
                    'Heart Days',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '记录爱与回忆的每一天',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 亮点功能标题
            const Text(
              '✨ 应用亮点',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            ...highlights.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                height: 100,
                // 固定统一高度
                width: double.infinity,
                // 👈 保证宽度占满父容器
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5C6BC0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          item['description']!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.justify, // 👈 让每行宽度一致
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),



            GestureDetector(
              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MqttPage()),
                );
              },
              child: // 开发者信息
              const Text(
                '👨‍💻 关于开发者',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            )
            ,
            const SizedBox(height: 12),
            Text(
              'Heart Days 由一位热爱生活与设计的开发者精心打造，致力于提升情侣、家庭之间的情感连接。',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),

            const SizedBox(height: 32),

            Center(
              child: Text(
                '版本号 v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
