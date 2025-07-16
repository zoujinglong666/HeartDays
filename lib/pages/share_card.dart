import 'package:flutter/material.dart';
import 'package:heart_days/components/BaseInfoCard.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:heart_days/components/AnimatedCardWrapper.dart';

class ShareCardPage extends StatelessWidget {
  const ShareCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('分享卡片'),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedCardWrapper(
              child: BaseInfoCard(
                emoji: '🎉',
                title: '我们的纪念日',
                subtitle: '与你一起的第100天',
                gradientColors: [Color(0xFFF48FB1), Color(0xFFCE93D8)],
                footer: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.favorite, color: Colors.pink.shade300, size: 20),
                      const SizedBox(width: 4),
                      Text('甜蜜时刻', style: TextStyle(color: Colors.pink.shade300, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.share),
                label: const Text('一键分享'),
                onPressed: () {
                  ToastUtils.showToast('已触发分享（可集成share_plus等）');
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '可将这张纪念卡片分享给好友或朋友圈，记录你们的美好时刻！',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
