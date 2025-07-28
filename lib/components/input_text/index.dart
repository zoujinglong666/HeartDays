import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/helper.dart';
import 'package:heart_days/components/Clickable.dart';

class InputText extends StatefulWidget {
  final bool password;

  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool expanded;
  final bool showCursor;
  final bool showClear;
  final bool showBorder;
  final bool showScrollbar;
  final bool canRequestFocus;
  final bool? enableInteractiveSelection;

  final Widget? icon;
  final String? label;
  final String? initialValue;
  final String? errorText;
  final String? placeholder;

  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final List<TextInputFormatter>? inputFormatters;

  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  final FocusNode? focusNode;
  final TextInputType? inputType;
  final TextInputAction? inputAction;

  final TextStyle? textStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final TextCapitalization textCapitalization;
  final TextAlignVertical? textAlignVertical;
  final TextEditingController? controller;

  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const InputText({
    super.key,
    this.password = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.expanded = false,
    this.showCursor = true,
    this.showClear = true,
    this.showBorder = false,
    this.showScrollbar = true,
    this.canRequestFocus = true,
    this.enableInteractiveSelection,
    this.icon,
    this.label,
    this.initialValue,
    this.errorText,
    this.placeholder,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.maxLengthEnforcement,
    this.inputFormatters,
    this.padding,
    this.borderRadius,
    this.focusNode,
    this.inputType,
    this.inputAction,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.textAlignVertical,
    this.controller,
    this.onTap,
    this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
  });

  @override
  State<StatefulWidget> createState() => _InputTextState();
}

class _InputTextState extends State<InputText> {
  late FocusNode focusNode;
  late TextStyle textStyle;
  late EdgeInsets padding;
  late TextEditingController controller;
  late ValueNotifier<String>? countNotifier;

  bool passwordInput = false;
  bool displayClear = false;

  @override
  void initState() {
    super.initState();
    passwordInput = widget.password;
    focusNode = widget.focusNode ?? FocusNode();
    textStyle = widget.textStyle ?? const TextStyle(fontSize: 14);
    padding = widget.padding ?? const EdgeInsets.all(10);
    controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    countNotifier =
    widget.maxLength == null ? null : ValueNotifier(controller.text);
    controller.addListener(_doValueChanged);
    displayClear = widget.showClear && Helper.isNotEmpty(controller.text);
  }

  @override
  void didUpdateWidget(covariant InputText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password) {
      passwordInput = widget.password;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      focusNode = widget.focusNode ?? FocusNode();
    }
    if (oldWidget.textStyle != widget.textStyle) {
      textStyle = widget.textStyle ?? const TextStyle(fontSize: 14);
    }
    if (oldWidget.padding != widget.padding) {
      padding = widget.padding ?? const EdgeInsets.all(10);
    }
    if (oldWidget.controller != widget.controller) {
      controller.removeListener(_doValueChanged);
      controller =
          widget.controller ?? TextEditingController(text: widget.initialValue);
      controller.addListener(_doValueChanged);
    }
    if (oldWidget.initialValue != widget.initialValue) {
      if (Helper.isNotEmpty(widget.initialValue)) {
        controller.text = widget.initialValue!;
      } else {
        controller.clear();
      }
    }
    displayClear = widget.showClear && Helper.isNotEmpty(controller.text);
    if (oldWidget.maxLength != widget.maxLength) {
      countNotifier =
      widget.maxLength == null ? null : ValueNotifier(controller.text);
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(_doValueChanged);
    controller.dispose();
    countNotifier?.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ixExpanded =
        widget.enabled && widget.maxLength != null && widget.expanded;
    Widget input = TextField(
      focusNode: focusNode,
      controller: controller,

      // 属性开关配置
      autocorrect: false,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      expands: widget.expanded,

      // 设置为密码输入框
      obscureText: passwordInput,
      // obscuringCharacter: '*',

      // 光标相关的配置项
      showCursor: widget.showCursor,
      cursorWidth: 3,
      cursorOpacityAnimates: true,

      // 文本样式配置
      style: textStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textAlignVertical: widget.textAlignVertical,
      textCapitalization: widget.textCapitalization,

      // 输入限制
      minLines:
      widget.expanded ? null : (widget.password ? 1 : widget.minLines),
      maxLines:
      widget.expanded ? null : (widget.password ? 1 : widget.maxLines),
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      enableInteractiveSelection: widget.enableInteractiveSelection,

      // 键盘配置
      keyboardType: widget.inputType,
      textInputAction: widget.inputAction,

      // 格式限制之类的
      inputFormatters: widget.inputFormatters,

      // 监听相关配置项
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      onTapOutside: (e) => focusNode.hasFocus ? focusNode.unfocus() : 0,

      // 装饰样式配置
      decoration: InputDecoration(
        enabled: false,
        isDense: true,
        isCollapsed: true,

        // 开启背景颜色填充
        filled: true,
        fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
          return states.contains(WidgetState.disabled)
              ? const Color(0xFFEDEDED) // 禁用模式下的背景颜色
              : Colors.white; // 正常模式下的背景颜色
        }),

        // 是否将标签和提示文本对齐
        alignLabelWithHint: false,

        // 错误信息展示（非 expanded 模式下生效）
        error: _createInputErrorText(),
        counter: countNotifier == null ? null : const SizedBox.shrink(),

        // 输入框的内间距
        contentPadding: ixExpanded ? padding.copyWith(bottom: 28) : padding,

        // 提示文本设置
        hintText: widget.placeholder,
        hintStyle: textStyle.copyWith(color: const Color(0xFFC8C8C8)),
        hintMaxLines: 1,
        floatingLabelBehavior: FloatingLabelBehavior.never,

        // 自定义前缀（图标&标签展示）
        prefixIcon: _createPrefixWidget(),
        prefixIconConstraints: const BoxConstraints(minWidth: 30),

        // 自定义尾缀（清除&计数器）
        suffixIcon: _createSuffixWidget(),
        suffixIconConstraints: const BoxConstraints(minWidth: 30),

        // 输入框边框样式设置
        border: InputBorder.none,
        enabledBorder: _createBorder(const Color(0xFFC8C8C8)),
        errorBorder: _createBorder(Colors.red),
        focusedBorder: _createBorder(Colors.blueAccent),
        focusedErrorBorder: _createBorder(Colors.red, 1),
        disabledBorder: _createBorder(const Color(0xFFBCBCBC)),
      ),
    );

    if (!widget.enabled) return input;
    input = widget.expanded ? _decorateTextArea(input) : input;
    return input;
  }

  /// 构建输入框边框
  ///
  /// * @param [color] - 边框颜色；
  /// * @param [width] - 边框粗细，默认 `0.5`；
  /// * @return [InputBorder]
  InputBorder? _createBorder(Color color, [double width = 0.5]) {
    return widget.showBorder
        ? OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      borderSide: BorderSide(width: width, color: color),
    )
        : null;
  }

  /// 构建输入左侧内容，涉及 `图标` 和 `标签文本`，两者均需添加对应设置项才会生效。
  ///
  /// * [icon] - 用于设置左侧围标；
  /// * [label] - 用于设置左侧标签文本；
  /// * @return [Widget] - 如果二者均未设置，将返回 `null`；
  Widget? _createPrefixWidget() {
    if (widget.expanded) return null;
    final isIconNull = widget.icon == null;
    final isLabelEmpty = Helper.isEmpty(widget.label);
    if (isIconNull && isLabelEmpty) return null;
    final theme = Theme.of(context);
    Widget? content;

    // 如果设置了图标，则构建图标并赋值给 content。
    if (!isIconNull) {
      if (widget.icon is Icon) {
        content = IconTheme(
          data: theme.iconTheme.copyWith(size: 16),
          child: widget.icon!,
        );
      } else {
        content = SizedBox(width: 20, child: widget.icon);
      }
    }

    // 如果设置了标签，则在混合 content 的值
    if (!isLabelEmpty) {
      final label = Text(
        widget.label!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle.copyWith(color: const Color(0xFF6F6F6F)),
      );
      if (content == null) {
        content = label;
      } else {
        content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [content, const SizedBox(width: 5), label],
        );
      }
    }

    // 返回最终构建的组件内容
    // 通过 Padding 设置左右两侧的间距，上下是垂直居中的，可以不用设置。
    return Padding(
      padding: EdgeInsets.only(left: padding.left, right: 5),
      child: content,
    );
  }

  /// 构建输入末尾内容，涉及 `计数器`、`密码切换` 和 `清除按钮`。
  ///
  /// * 当设置 [widget.maxLength] 后将自动开启输入计数器，该内容位于输入框末尾；
  /// * 密码切换 `小眼睛` 无需设置，当输入模式设置成 [widget.password] 后自动生效；
  /// * 开启 [widget.showClear] 后，会在最末尾生成一个 `x` 形状的清除按钮，点击可清空输入内容；
  /// * @return [Widget] - 如果对应的参数均未设置，将返回 `null`；
  Widget? _createSuffixWidget() {
    if (widget.expanded || !widget.enabled) return null;
    final items = <Widget>[];

    // 添加输入数量计数
    if (countNotifier != null) {
      items.add(_createCountNotifier());
    }

    // 密码明文切换显示  ios fengge passwordInput ? CupertinoIcons.eye_slash : CupertinoIcons.eye
    if (widget.password) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(width: 5));
      }
      items.add(Clickable(
        onTap: () => setState(() => passwordInput = !passwordInput),
        child: Icon(
          passwordInput ? Icons.visibility_off : Icons.visibility,
          size: 19,
          color: const Color(0xFF636363),
        ),
      ));
    }

    // 清除按钮
    if (widget.showClear) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(width: 5));
      }
      items.add(Visibility(
        visible: displayClear,
        child: Clickable(
          onTap: () {
            controller.clear();
            widget.onClear?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFB5B5B5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.clear,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
      ));
    }

    // 返回最终构建的组件内容
    // 通过 Padding 设置左右两侧的间距，上下是垂直居中的，可以不用设置。
    return Padding(
      padding: EdgeInsets.only(right: padding.right, left: 5),
      child: items.length == 1
          ? items[0]
          : Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

  /// 当设置 [widget.maxLength] 后，会自动开启输入计数器显示，由于计数器需要高频刷新，
  /// 所以这里采用 `ValueNotifier` + `ValueListenableBuilder` 的模式实现局部刷新，
  /// 当输入内容发生变更后，会触发 `ValueListenableBuilder` 的重构操作，以此刷新计数器内容。
  Widget _createCountNotifier() {
    return ValueListenableBuilder(
      valueListenable: countNotifier!,
      builder: (context, text, child) {
        final len = text.length, max = widget.maxLength!;
        return Text(
          "$len/$max",
          style: textStyle.copyWith(
              color: len > max ? Colors.red : const Color(0xFF777777)),
        );
      },
    );
  }

  /// 创建输入错误显示内容，生效条件将依赖于 [widget.expanded] 和 [widget.errorText]，
  /// 仅当 [widget.expanded] 为 false，并且设置了 [widget.errorText] 时才会显示输入框底部的错误信息。
  Widget? _createInputErrorText() {
    if (widget.expanded || Helper.isEmpty(widget.errorText)) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        widget.errorText!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle.copyWith(fontSize: 12, color: Colors.red),
      ),
    );
  }

  /// 装饰 [widget.expanded] 状态在的输入框，这里我称之为 `文本域`，
  /// 它的表现为尽最大肯的撑满父组件的空间，如果父组件未设置尺寸约束，则会向上延伸，
  /// 直到找到最近一个设置了尺寸的组件为止。
  ///
  /// * 如果启用了 [widget.showScrollbar] 则会在内容超出输入框限制后在右侧显示一个滚动条；
  /// * 如果设置了 [widget.errorText]，会和普通模式不太一样，此方法会在输入框底部显示错误信息；
  /// * 如果同时设置了 [widget.maxLength] 的话，由于文本域的特殊性，计数器会在底部右下角显示；
  Widget _decorateTextArea(Widget input) {
    if (widget.showScrollbar) {
      input = Scrollbar(child: input);
    }
    final hasErrorText = Helper.isNotEmpty(widget.errorText);
    final hasCounter = countNotifier != null;
    if (!hasErrorText && !hasCounter) return input;
    final items = <Widget>[];

    // 构建错误信息
    if (hasErrorText) {
      Widget error = Text(
        widget.errorText!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle.copyWith(fontSize: 12, color: Colors.red),
      );
      items.add(hasCounter ? Expanded(child: error) : error);
    }

    // 构建输入计数器
    if (hasCounter) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(width: 5));
      }
      items.add(_createCountNotifier());
    }

    // 返回组合的内容
    return Stack(alignment: Alignment.bottomCenter, children: [
      input,
      Container(
        margin: const EdgeInsets.only(left: 1, right: 1, bottom: 1),
        padding: padding.copyWith(top: 3, bottom: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: items),
      ),
    ]);
  }

  /// 文本内容变化监器，注册监听后，输入框内容发生变化时会回调此函数。
  ///
  /// 此方法主要处理两个逻辑：
  /// * 将输入内容导入到 [countNotifier] 中，以此更新计数器的内容显示；
  /// * 根据输入内容的变化，适当地更新 [displayClear] 的值，这会导致末尾的清除按钮显示或隐藏；
  void _doValueChanged() {
    countNotifier?.value = controller.text;
    if (!widget.showClear) return;
    if (Helper.isNotEmpty(controller.text)) {
      if (!displayClear) {
        displayClear = true;
        setState(Consts.doNothing);
      }
    } else if (displayClear) {
      displayClear = false;
      setState(Consts.doNothing);
    }
  }
}