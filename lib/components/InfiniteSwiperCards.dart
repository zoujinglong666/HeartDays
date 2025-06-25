import 'dart:async';
import 'package:flutter/material.dart';

class InfiniteSwiperCards extends StatefulWidget {
  final List<Widget> cards;
  final Duration interval;

  const InfiniteSwiperCards({
    Key? key,
    required this.cards,
    this.interval = const Duration(seconds: 5),
  }) : super(key: key);

  @override
  State<InfiniteSwiperCards> createState() => _InfiniteSwiperCardsState();
}

class _InfiniteSwiperCardsState extends State<InfiniteSwiperCards>
    with TickerProviderStateMixin {
  late PageController _controller;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 1000 * (widget.cards.isEmpty ? 1 : widget.cards.length));
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.cards.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      _current++;
      _controller.animateToPage(
        _current,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink(); // 或者展示一个提示
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final realIndex = index % widget.cards.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: widget.cards[realIndex],
          );
        },
        onPageChanged: (index) => _current = index,
      ),
    );
  }
}
