import 'package:flutter/material.dart';
import 'package:heart_days/components/Clickable.dart';
import 'package:heart_days/components/selectable/base_bottom_sheet.dart';

class Option<T> {
  final String label;
  final T value;
  final Widget? icon;

  const Option({
    required this.label,
    required this.value,
    this.icon,
  });

  Option.fromJson(Map<String, dynamic> json)
      : this(label: json["label"], value: json["value"]);

  @override
  Map<String, dynamic> toJson() => {"label": label, "value": value};

  @override
  String toString() => 'Option(label: $label, value: $value)';
}
class Selectable<T> extends BaseBottomSheet<List<Option<T>>> {
  final List<Option<T>> options;
  final List<T>? initialValue;
  final bool multiple;

  Selectable({
    required super.context,
    required this.options,
    this.initialValue,
    this.multiple = false,
    super.title,
    super.isDismissible,
    super.radius,
    super.spacing,
    super.showHeader,
    super.showFooter,
    super.showClose,

  }) : super(widget: _SelectableWidget());

  @override
  void confirm() => Navigator.of(context).maybePop(_selectedValues.toList());

  final Set<Option<T>> _selectedValues = {};

  void _clearAll() => _selectedValues.clear();

  void _addItem(Option<T> option) => _selectedValues.add(option);

  void _removeItem(Option<T> option) => _selectedValues.remove(option);

  bool _contains(Option<T> option) => _selectedValues.contains(option);
}

class _SelectableWidget<T> extends BottomSheetWidget<Selectable<T>> {
  Option<T>? lastSelected;

  /// 列表项元素大于 6 个以后底部会多展示一个 “取消” 按钮
  @override
  bool hasCancelButton() => parent.options.length > 6;

  @override
  void onInitialized() {
    if (parent.initialValue?.isNotEmpty ?? false) {
      for (Option<T> option in parent.options) {
        if (parent.initialValue!.contains(option.value)) {
          parent._addItem(option);
        }
      }
    }
  }

  @override
  Widget body(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true, // 列表高度自适应
      padding: EdgeInsets.zero, // 去除 ListView 默认内间距
      physics: hasCancelButton()
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : const NeverScrollableScrollPhysics(),
      itemCount: parent.options.length,
      itemBuilder: buildItem,
      separatorBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(border: Border(bottom: border)),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    final List<Widget> items = [];
    final Option<T> option = parent.options[index];
    final selected = parent._contains(option);

    // 自定义图标
    if (option.icon != null) {
      items.add(Padding(
        padding: EdgeInsets.only(right: parent.spacing),
        child: option.icon!,
      ));
    }

    // 显示文本
    items.add(Expanded(
      child: Text(
        option.label,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
    ));

    // 选中状态
    items.add(Padding(
      padding: EdgeInsets.only(left: parent.spacing),
      child: Icon(
        Icons.check,
        size: 20,
        color: selected ? Colors.redAccent : Colors.transparent,
      ),
    ));

    /// Clickable 是上一期（第32期 - 万能点击组件）那一期的内容；
    return Clickable(
      color: Colors.white,
      pressedColor: const Color(0xFFF4F4F4),
      onTap: () => onSelected(option),
      child: Padding(
        padding: parent.padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: items,
        ),
      ),
    );
  }

  /// 执行列表点击逻辑
  void onSelected(Option<T> selected) {
    if (lastSelected != selected || parent.multiple) {
      if (parent.multiple) {
        parent._contains(selected)
            ? parent._removeItem(selected)
            : parent._addItem(selected);
      } else {
        parent._clearAll();
        parent._addItem(selected);
      }
      lastSelected = selected;
      setState(() => {});
    }
  }
}