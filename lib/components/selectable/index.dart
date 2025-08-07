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
  /// 🔧 添加这个字段
  final ValueChanged<List<Option<T>>>? onChange;
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
    this.onChange, // ← 新增

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
        Icons.check_rounded,
        size: 20,
        color: selected ? Colors.green : Colors.transparent,
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
  // void onSelected(Option<T> selected) {
  //   // if (parent.multiple) {
  //   //   parent._contains(selected)
  //   //       ? parent._removeItem(selected)
  //   //       : parent._addItem(selected);
  //   // } else {
  //   //   parent._clearAll();
  //   //   parent._addItem(selected);
  //   // }
  //   if (lastSelected != selected || parent.multiple) {
  //     if (parent.multiple) {
  //       parent._contains(selected)
  //           ? parent._removeItem(selected)
  //           : parent._addItem(selected);
  //     } else {
  //       parent._clearAll();
  //       parent._addItem(selected);
  //     }
  //     lastSelected = selected;
  //     setState(() => {});
  //   }
  // }

  void onSelected(Option<T> selected) {
    if (parent.multiple) {
      // ✅ 多选逻辑：已有就移除，否则添加
      parent._contains(selected)
          ? parent._removeItem(selected)
          : parent._addItem(selected);
    } else {
      // ✅ 单选逻辑：如果再次点击同一个选项，取消选中；否则选中新项
      if (parent._contains(selected)) {
        parent._removeItem(selected);
        lastSelected = null;
      } else {
        parent._clearAll();
        parent._addItem(selected);
        lastSelected = selected;
      }
    }
    // ✅ 触发 onChange 回调
    parent.onChange?.call(parent._selectedValues.toList());
    setState(() {});
  }

}