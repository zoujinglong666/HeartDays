import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:heart_days/common/decode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';


// 自定义样式配置
class PaginatedListStyle {
  final Color loadingColor;
  final TextStyle textStyle;
  final double spacing;

  const PaginatedListStyle({
    this.loadingColor = Colors.blue,
    this.textStyle = const TextStyle(fontSize: 14),
    this.spacing = 12,
  });
}

// 回调类型
typedef ItemBuilder<T> =
    Widget Function(BuildContext context, T item, int index);
typedef PageFetcher<T> =
    Future<PaginatedData<T>> Function(int pageNum, int pageSize);

class LoadMoreList<T> extends StatefulWidget {
  final PageFetcher<T> fetchPage;
  final ItemBuilder<T> itemBuilder;
  final int pageSize;
  final String? cacheKey;
  final PaginatedListStyle? style;
  final bool useGrid;
  final int gridCrossAxisCount;

  const LoadMoreList({
    super.key,
    required this.fetchPage,
    required this.itemBuilder,
    this.pageSize = 10,
    this.cacheKey,
    this.style,
    this.useGrid = false,
    this.gridCrossAxisCount = 2,
  });

  @override
  State<LoadMoreList<T>> createState() => _LoadMoreListState<T>();
}

class _LoadMoreListState<T> extends State<LoadMoreList<T>> {
  final List<T> _items = [];
  int _pageNum = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _error = false;
  late EasyRefreshController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EasyRefreshController(controlFinishLoad: true);
    _loadCachedData();
    _onRefresh();
  }

  Future<void> _loadCachedData() async {
    if (widget.cacheKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(widget.cacheKey!);
    if (cached != null && mounted) {
      setState(() {
        _items.addAll(cached.map((e) => e as T));
      });
    }
  }

  Future<void> _cacheData(List<T> list) async {
    if (widget.cacheKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(widget.cacheKey!, list.cast<String>());
  }

  Future<void> _onRefresh() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final res = await widget.fetchPage(1, widget.pageSize);

      setState(() {
        _items.clear();
        _items.addAll(res.records);
        _hasMore = res.hasNext;
        _pageNum = 2;
        _loading = false;
      });
      _controller.finishRefresh(); // 通知刷新完成
      _controller.resetFooter();   // 重置 footer 状态
      _cacheData(res.records);
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  Future<void> _onLoad() async {
    if (!_hasMore) {
      _controller.finishLoad(IndicatorResult.noMore);
      return;
    }
    try {
      final res = await widget.fetchPage(_pageNum, widget.pageSize);
      final newItems = res.records.where((e) => !_items.contains(e)).toList();
      setState(() {
        _items.addAll(newItems);
        _hasMore = res.hasNext;
        _pageNum++;
      });
      _controller.finishLoad(_hasMore ? IndicatorResult.success : IndicatorResult.noMore);
    } catch (e) {
      print('加载错误: $e');
      _error = true;
      _controller.finishLoad(IndicatorResult.fail);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder:
            (_, i) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListTile(
                title: Container(height: 20, color: Colors.white),
              ),
            ),
      );
    }

    if (_error && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("加载失败"),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _onRefresh, child: const Text("重试")),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(child: Text("暂无数据"));
    }

    return EasyRefresh(
      onRefresh: _onRefresh,
      onLoad: _hasMore ? _onLoad : null,
      header: ClassicHeader(
        dragText: '下拉刷新',
        armedText: '释放刷新',
        readyText: '刷新中...',
        processingText: '刷新中...',
        processedText: '刷新成功',
        noMoreText: '没有更多了',
        messageText: '上次更新时间：%T',
      ),
      footer: ClassicFooter(
        dragText: '上拉加载更多',
        armedText: '释放加载',
        readyText: '加载中...',
        processingText: '加载中...',
        processedText: _hasMore ? '加载完成' : '没有更多了',
        noMoreText: '✅ 没有更多了',
        failedText: '❌ 加载失败，点击重试',
        messageText: '上次更新时间：%T',
      ),
      child:
          widget.useGrid
              ? GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.gridCrossAxisCount,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: _items.length,
                itemBuilder:
                    (context, index) =>
                        widget.itemBuilder(context, _items[index], index),
              )
              : ListView.builder(
                itemCount: _items.length,
                itemBuilder:
                    (context, index) =>
                        widget.itemBuilder(context, _items[index], index),
              ),
    );
  }
}
