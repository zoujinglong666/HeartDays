import 'package:flutter/material.dart';
import 'package:heart_days/components/RefreshList.dart';

class MyListPage extends StatelessWidget {
  const MyListPage({super.key});

  // 模拟 API 请求
  // 模拟分页函数
  Future<PageResult<String>> fetchData(int page, int size) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (page > 3) return PageResult(list: [], hasMore: false);
    final items = List.generate(size, (i) => '第 $page 页 Item ${i + 1}');
    return PageResult(list: items, hasMore: page < 10);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('分页加载示例')),
      body: PaginatedListView<String>(
      fetchPage: fetchData,
      itemBuilder: (ctx, item, index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          title: Text(item),
          leading: const Icon(Icons.label_important_outline),
        ),
      ),
      useGrid: false,
      cacheKey: 'demo_cache',
      style: PaginatedListStyle(
        loadingColor: Colors.teal,
        textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
        spacing: 16,
      ),
    ),
    );
  }
}
