import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私说明')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _PrivacySection(
              title: '本地优先',
              content: '你的任务、短期状态、生活事件和长期画像默认保存在本机数据库里。',
            ),
            _PrivacySection(
              title: 'AI 解析会发送当前输入',
              content:
                  '当你点击整理时，当前输入会发送到我们的 API proxy，再由 API proxy 调用 DeepSeek。API Key 不会放进手机 App。',
            ),
            _PrivacySection(
              title: '你可以删除记忆',
              content: '记忆管理页会让你查看系统记住了什么。删除后，这条记忆不会继续参与首页建议。',
            ),
            _PrivacySection(
              title: '长期画像必须确认',
              content: '长期画像只有在你确认后才会生效。AI 的自动猜测不能直接变成你的长期记忆。',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}
