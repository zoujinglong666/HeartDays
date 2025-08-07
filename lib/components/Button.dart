import 'package:flutter/material.dart';

typedef ButtonCallback = void Function(Button button);

// 按钮类型
enum ButtonType {
  DEFAULT,
  PRIMARY,
  SUCCESS,
  INFO,
  WARN,
  DANGER,
}

class Button extends StatefulWidget {
  final String text; // 按钮文字
  final TextStyle? style; // 文字样式
  final EdgeInsets? margin; // 按钮外间距
  final EdgeInsets? padding; // 按钮内间距
  final Widget? icon; // 按钮的图标
  final Border? border; // 按钮边框
  final BorderRadius? radius; // 按钮的圆角
  final ButtonType type; // 按钮类型
  final ButtonCallback? onTap; // 按钮点击事件
  final  bool? block; // 按钮点击事件

  const Button({
    super.key,
    required this.text,
    this.style,
    this.margin,
    this.padding,
    this.icon,
    this.border,
    this.radius,
    this.type = ButtonType.DEFAULT,
    this.onTap,
    this.block,
  });

  @override
  State<Button> createState() => _MyButtonState();
}

class _MyButtonState extends State<Button> {
  Color? _bgColor; // 当前按钮的背景颜色
  Color? _textColor; // 当前文字颜色

  @override
  void initState() {
    super.initState();
    _switchStyle(active: false);
  }

  @override
  void didUpdateWidget(Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _switchStyle(active: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _switchStyle(active: false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body = DefaultTextStyle(
      style: TextStyle(color: _textColor),
      child: Text(widget.text, style: widget.style),
    );

    if (widget.icon != null) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(data: IconThemeData(color: _textColor), child: widget.icon!),
          const SizedBox(width: 5),
          body,
        ],
      );
    }

    BoxDecoration decoration = BoxDecoration(
      color: _bgColor,
      border: widget.border,
      borderRadius: widget.radius ?? BorderRadius.circular(100),
      boxShadow: [
        BoxShadow(
          color: _bgColor!.withAlpha(120),
          blurRadius: 10,
          offset: const Offset(0, 5),
          spreadRadius: 1,
        ),
      ],
    );

    body = Container(
      decoration: decoration,
      padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      margin: widget.margin,
      child: body,
    );
    // ✅ 自动撑满宽度（block=true时）
    if (widget.block == true) {
      body = SizedBox(width: double.infinity, child: body);
    }
    return GestureDetector(
      onTapDown: (_) => _switchStyle(active: true),
      onTapUp: (_) => _resetStyle(),
      onTapCancel: _resetStyle,
      child: body,
    );
  }

  void _resetStyle() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _switchStyle(active: false);
      widget.onTap?.call(widget);
    });
  }

  void _switchStyle({required bool active}) {
    switch (widget.type) {
      case ButtonType.DEFAULT:
        _bgColor = active ? Colors.grey[800] : Colors.grey[900];
        _textColor = Colors.white;
        break;
      case ButtonType.PRIMARY:
        _bgColor = active ? Colors.blueAccent[400] : Colors.blueAccent[700];
        _textColor = Colors.white;
        break;
      case ButtonType.SUCCESS:
        _bgColor = active ? Colors.green[800] : Colors.green[900];
        _textColor = Colors.white;
        break;
      case ButtonType.INFO:
        _bgColor = active ? Colors.cyan[800] : Colors.cyan[900];
        _textColor = Colors.white;
        break;
      case ButtonType.WARN:
        _bgColor = active ? Colors.orange[700] : Colors.orange[800];
        _textColor = Colors.black;
        break;
      case ButtonType.DANGER:
        _bgColor = active ? Colors.red[400] : Colors.red[700];
        _textColor = Colors.white;
        break;
    }
    if (mounted) {
      setState(() {});
    }
  }
}
