import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PressType {
  longPress,
  singleClick,
}

enum PreferredPosition {
  top,
  bottom,
}

class ComPopupMenuController extends ChangeNotifier {
  bool menuIsShowing = false;

  void showMenu() {
    menuIsShowing = true;
    notifyListeners();
  }

  void hideMenu() {
    menuIsShowing = false;
    notifyListeners();
  }

  void toggleMenu() {
    menuIsShowing = !menuIsShowing;
    notifyListeners();
  }
}

Rect _menuRect = Rect.zero;

class ComPopupMenu extends StatefulWidget {
  const ComPopupMenu({
    super.key,
    required this.child,
    required this.menuBuilder,
    this.pressType = PressType.singleClick,
    this.controller,
    this.arrowColor,
    this.showArrow = true,
    this.barrierColor = Colors.black12,
    this.arrowSize = 14.0,
    this.horizontalMargin = 16.0,
    this.verticalMargin = 4.0,
    this.position,
    this.menuOnChange,
    this.enablePassEvent = true,
    this.closeOnItemClick = true,
  });

  final Widget child;
  final PressType pressType;
  final bool showArrow;
  final Color? arrowColor;
  final Color barrierColor;
  final double horizontalMargin;
  final double verticalMargin;
  final double arrowSize;
  final ComPopupMenuController? controller;
  final Widget? menuBuilder;
  final PreferredPosition? position;
  final bool closeOnItemClick;
  final void Function(bool)? menuOnChange;

  /// Pass tap event to the widgets below the mask.
  /// It only works when [barrierColor] is transparent.
  final bool enablePassEvent;

  @override
  ComPopupMenuState createState() => ComPopupMenuState();
}

class ComPopupMenuState extends State<ComPopupMenu> {
  RenderBox? _childBox;
  RenderBox? _parentBox;
  OverlayEntry? _overlayEntry;
  ComPopupMenuController? _controller;
  bool _canResponse = true;

  _showMenu() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        Widget arrow = ClipPath(
          clipper: _ArrowClipper(),
          child: Container(
            width: widget.arrowSize,
            height: widget.arrowSize,
            color: widget.arrowColor ??
                Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
        );

        Widget menu = Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: _parentBox!.size.width - 2 * widget.horizontalMargin,
              minWidth: 0,
            ),
            child: CustomMultiChildLayout(
              delegate: _MenuLayoutDelegate(
                anchorSize: _childBox!.size,
                anchorOffset: _childBox!.localToGlobal(
                  Offset(-widget.horizontalMargin, 0),
                ),
                verticalMargin: widget.verticalMargin,
                position: widget.position,
              ),
              children: <Widget>[
                if (widget.showArrow)
                  LayoutId(
                    id: _MenuLayoutId.arrow,
                    child: arrow,
                  ),
                if (widget.showArrow)
                  LayoutId(
                    id: _MenuLayoutId.downArrow,
                    child: Transform.rotate(
                      angle: math.pi,
                      child: arrow,
                    ),
                  ),
                LayoutId(
                  id: _MenuLayoutId.content,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Material(
                        color: Colors.transparent,
                        child: widget.closeOnItemClick
                            ? _wrapMenuItems(widget.menuBuilder)
                            : widget.menuBuilder,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        return Listener(
          behavior: widget.enablePassEvent
              ? HitTestBehavior.translucent
              : HitTestBehavior.opaque,
          onPointerDown: (PointerDownEvent event) {
            Offset offset = event.localPosition;
            // If tap position in menu
            if (_menuRect.contains(
                Offset(offset.dx - widget.horizontalMargin, offset.dy))) {
              return;
            }
            _controller?.hideMenu();
            // When [enablePassEvent] works and we tap the [child] to [hideMenu],
            // but the passed event would trigger [showMenu] again.
            // So, we use time threshold to solve this bug.
            _canResponse = false;
            Future.delayed(const Duration(milliseconds: 300))
                .then((_) => _canResponse = true);
          },
          child: widget.barrierColor == Colors.transparent
              ? menu
              : Container(
            color: widget.barrierColor,
            child: menu,
          ),
        );
      },
    );
    if (_overlayEntry != null) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  _hideMenu() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  _updateView() {
    bool menuIsShowing = _controller?.menuIsShowing ?? false;
    widget.menuOnChange?.call(menuIsShowing);
    if (menuIsShowing) {
      _showMenu();
    } else {
      _hideMenu();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller ??= ComPopupMenuController();
    _controller?.addListener(_updateView);
    WidgetsBinding.instance.addPostFrameCallback((call) {
      if (mounted) {
        _childBox = context.findRenderObject() as RenderBox?;
        _parentBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
      }
    });
  }

  @override
  void dispose() {
    _hideMenu();
    _controller?.removeListener(_updateView);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var child = Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: widget.child,
        onTap: () {
          if (widget.pressType == PressType.singleClick && _canResponse) {
            _controller?.showMenu();
          }
        },
        onLongPress: () {
          if (widget.pressType == PressType.longPress && _canResponse) {
            _controller?.showMenu();
          }
        },
      ),
    );
    if (!kIsWeb && Platform.isIOS) {
      return child;
    } else {
      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (bool canPop, _) {
          _hideMenu();
        },
        child: child,
      );
    }
  }

  // 包装菜单项以实现自动关闭功能
  Widget _wrapMenuItems(Widget? menuBuilder) {
    if (menuBuilder == null) return const SizedBox.shrink();

    return _MenuItemsWrapper(
      controller: _controller,
      child: menuBuilder,
    );
  }
}

// 创建一个新的 widget 来包装菜单项
class _MenuItemsWrapper extends StatefulWidget {
  final ComPopupMenuController? controller;
  final Widget child;

  const _MenuItemsWrapper({
    required this.controller,
    required this.child,
  });

  @override
  _MenuItemsWrapperState createState() => _MenuItemsWrapperState();
}

class _MenuItemsWrapperState extends State<_MenuItemsWrapper> {
  @override
  Widget build(BuildContext context) {
    return _wrapWidget(widget.child);
  }

  Widget _wrapWidget(Widget child) {
    // 如果是 InkWell 或 GestureDetector，包装其点击事件
    if (child is InkWell) {
      return InkWell(
        key: child.key,
        onTap: () {
          widget.controller?.hideMenu();
          if (child.onTap != null) {
            // 延迟执行原始点击事件，确保菜单关闭动画完成
            Future.delayed(const Duration(milliseconds: 100), () {
              child.onTap!();
            });
          }
        },
        onLongPress: child.onLongPress,
        onDoubleTap: child.onDoubleTap,
        child: child.child != null ? _wrapWidget(child.child!) : null,
      );
    } else if (child is GestureDetector) {
      return GestureDetector(
        key: child.key,
        onTap: () {
          widget.controller?.hideMenu();
          if (child.onTap != null) {
            Future.delayed(const Duration(milliseconds: 100), () {
              child.onTap!();
            });
          }
        },
        onLongPress: child.onLongPress,
        onDoubleTap: child.onDoubleTap,
        child: child.child != null ? _wrapWidget(child.child!) : null,
      );
    } else if (child is ListTile) {
      return ListTile(
        key: child.key,
        leading: child.leading,
        title: child.title,
        subtitle: child.subtitle,
        trailing: child.trailing,
        onTap: () {
          widget.controller?.hideMenu();
          if (child.onTap != null) {
            Future.delayed(const Duration(milliseconds: 100), () {
              child.onTap!();
            });
          }
        },
        onLongPress: child.onLongPress,
        enabled: child.enabled,
        dense: child.dense,
        visualDensity: child.visualDensity,
        shape: child.shape,
        contentPadding: child.contentPadding,
        selected: child.selected,
        selectedColor: child.selectedColor,
        iconColor: child.iconColor,
        textColor: child.textColor,
      );
    } else if (child is Container) {
      return Container(
        key: child.key,
        alignment: child.alignment,
        padding: child.padding,
        color: child.color,
        decoration: child.decoration,
        foregroundDecoration: child.foregroundDecoration,
        width: child.constraints?.maxWidth,
        height: child.constraints?.maxHeight,
        constraints: child.constraints,
        margin: child.margin,
        transform: child.transform,
        child: child.child != null ? _wrapWidget(child.child!) : null,
      );
    } else if (child is Column) {
      return Column(
        key: child.key,
        mainAxisAlignment: child.mainAxisAlignment,
        mainAxisSize: child.mainAxisSize,
        crossAxisAlignment: child.crossAxisAlignment,
        textDirection: child.textDirection,
        verticalDirection: child.verticalDirection,
        textBaseline: child.textBaseline,
        children: child.children.map((w) => _wrapWidget(w)).toList(),
      );
    } else if (child is Row) {
      return Row(
        key: child.key,
        mainAxisAlignment: child.mainAxisAlignment,
        mainAxisSize: child.mainAxisSize,
        crossAxisAlignment: child.crossAxisAlignment,
        textDirection: child.textDirection,
        verticalDirection: child.verticalDirection,
        textBaseline: child.textBaseline,
        children: child.children.map((w) => _wrapWidget(w)).toList(),
      );
    } else if (child is SingleChildRenderObjectWidget) {
      // 处理其他单子组件的 widget
      // 不进行递归包装，直接返回原始 widget
      return child;
    }

    // 对于其他类型的 widget，直接返回
    return child;
  }
}

enum _MenuLayoutId {
  arrow,
  downArrow,
  content,
}

enum _MenuPosition {
  bottomLeft,
  bottomCenter,
  bottomRight,
  topLeft,
  topCenter,
  topRight,
}

class _MenuLayoutDelegate extends MultiChildLayoutDelegate {
  _MenuLayoutDelegate({
    required this.anchorSize,
    required this.anchorOffset,
    required this.verticalMargin,
    this.position,
  });

  final Size anchorSize;
  final Offset anchorOffset;
  final double verticalMargin;
  final PreferredPosition? position;

  @override
  void performLayout(Size size) {
    Size contentSize = Size.zero;
    Size arrowSize = Size.zero;
    Offset contentOffset = const Offset(0, 0);
    Offset arrowOffset = const Offset(0, 0);

    double anchorCenterX = anchorOffset.dx + anchorSize.width / 2;
    double anchorTopY = anchorOffset.dy;
    double anchorBottomY = anchorTopY + anchorSize.height;
    _MenuPosition menuPosition = _MenuPosition.bottomCenter;

    if (hasChild(_MenuLayoutId.content)) {
      contentSize = layoutChild(
        _MenuLayoutId.content,
        BoxConstraints.loose(size),
      );
    }
    if (hasChild(_MenuLayoutId.arrow)) {
      arrowSize = layoutChild(
        _MenuLayoutId.arrow,
        BoxConstraints.loose(size),
      );
    }
    if (hasChild(_MenuLayoutId.downArrow)) {
      layoutChild(
        _MenuLayoutId.downArrow,
        BoxConstraints.loose(size),
      );
    }

    bool isTop = false;
    if (position == null) {
      // auto calculate position
      isTop = anchorBottomY > size.height / 2;
    } else {
      isTop = position == PreferredPosition.top;
    }
    if (anchorCenterX - contentSize.width / 2 < 0) {
      menuPosition = isTop ? _MenuPosition.topLeft : _MenuPosition.bottomLeft;
    } else if (anchorCenterX + contentSize.width / 2 > size.width) {
      menuPosition = isTop ? _MenuPosition.topRight : _MenuPosition.bottomRight;
    } else {
      menuPosition =
      isTop ? _MenuPosition.topCenter : _MenuPosition.bottomCenter;
    }

    switch (menuPosition) {
      case _MenuPosition.bottomCenter:
        arrowOffset = Offset(
          anchorCenterX - arrowSize.width / 2,
          anchorBottomY + verticalMargin,
        );
        contentOffset = Offset(
          anchorCenterX - contentSize.width / 2,
          anchorBottomY + verticalMargin + arrowSize.height,
        );
        break;
      case _MenuPosition.bottomLeft:
        arrowOffset = Offset(anchorCenterX - arrowSize.width / 2,
            anchorBottomY + verticalMargin);
        contentOffset = Offset(
          0,
          anchorBottomY + verticalMargin + arrowSize.height,
        );
        break;
      case _MenuPosition.bottomRight:
        arrowOffset = Offset(anchorCenterX - arrowSize.width / 2,
            anchorBottomY + verticalMargin);
        contentOffset = Offset(
          size.width - contentSize.width,
          anchorBottomY + verticalMargin + arrowSize.height,
        );
        break;
      case _MenuPosition.topCenter:
        arrowOffset = Offset(
          anchorCenterX - arrowSize.width / 2,
          anchorTopY - verticalMargin - arrowSize.height,
        );
        contentOffset = Offset(
          anchorCenterX - contentSize.width / 2,
          anchorTopY - verticalMargin - arrowSize.height - contentSize.height,
        );
        break;
      case _MenuPosition.topLeft:
        arrowOffset = Offset(
          anchorCenterX - arrowSize.width / 2,
          anchorTopY - verticalMargin - arrowSize.height,
        );
        contentOffset = Offset(
          0,
          anchorTopY - verticalMargin - arrowSize.height - contentSize.height,
        );
        break;
      case _MenuPosition.topRight:
        arrowOffset = Offset(
          anchorCenterX - arrowSize.width / 2,
          anchorTopY - verticalMargin - arrowSize.height,
        );
        contentOffset = Offset(
          size.width - contentSize.width,
          anchorTopY - verticalMargin - arrowSize.height - contentSize.height,
        );
        break;
    }
    if (hasChild(_MenuLayoutId.content)) {
      positionChild(_MenuLayoutId.content, contentOffset);
    }

    _menuRect = Rect.fromLTWH(
      contentOffset.dx,
      contentOffset.dy,
      contentSize.width,
      contentSize.height,
    );
    bool isBottom = false;
    if (_MenuPosition.values.indexOf(menuPosition) < 3) {
      // bottom
      isBottom = true;
    }
    if (hasChild(_MenuLayoutId.arrow)) {
      positionChild(
        _MenuLayoutId.arrow,
        isBottom
            ? Offset(arrowOffset.dx, arrowOffset.dy + 0.1)
            : const Offset(-100, 0),
      );
    }
    if (hasChild(_MenuLayoutId.downArrow)) {
      positionChild(
        _MenuLayoutId.downArrow,
        !isBottom
            ? Offset(arrowOffset.dx, arrowOffset.dy - 0.1)
            : const Offset(-100, 0),
      );
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) => false;
}

class _ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width / 2, size.height / 2);
    path.lineTo(size.width, size.height);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
