import 'package:flutter/material.dart';

/// 通用的下拉刷新列表组件
class RefreshableListView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const RefreshableListView({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 2.0,
      child: child,
    );
  }
}

/// 带空状态的下拉刷新列表
class RefreshableListViewWithEmpty extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const RefreshableListViewWithEmpty({
    super.key,
    required this.onRefresh,
    required this.children,
    this.emptyWidget,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 2.0,
      child: children.isEmpty
          ? ListView(
              padding: padding,
              physics: physics,
              shrinkWrap: shrinkWrap,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                ),
                emptyWidget ?? const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无数据',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: padding,
              physics: physics,
              shrinkWrap: shrinkWrap,
              children: children,
            ),
    );
  }
}

/// 带构建器的下拉刷新列表
class RefreshableListViewBuilder extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Widget? emptyWidget;

  const RefreshableListViewBuilder({
    super.key,
    required this.onRefresh,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 2.0,
      child: itemCount == 0
          ? ListView(
              padding: padding,
              physics: physics,
              shrinkWrap: shrinkWrap,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                ),
                emptyWidget ?? const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无数据',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: padding,
              physics: physics,
              shrinkWrap: shrinkWrap,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            ),
    );
  }
} 