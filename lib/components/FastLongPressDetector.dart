import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class FastLongPressDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final Duration duration;

  const FastLongPressDetector({
    super.key,
    required this.child,
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        _FastLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            _FastLongPressGestureRecognizer
        >(() => _FastLongPressGestureRecognizer(duration: duration), (
            _FastLongPressGestureRecognizer instance,
            ) {
          instance.onLongPress = onLongPress;
        }),
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _FastLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _FastLongPressGestureRecognizer({required Duration duration})
      : super(duration: duration);
}