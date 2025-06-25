import 'package:flutter/material.dart';

class SwiperCardView extends StatefulWidget {
  final List<Widget> cards;
  final Duration interval;

  const SwiperCardView({
    required this.cards,
    this.interval = const Duration(seconds: 5),
    super.key,
  });

  @override
  State<SwiperCardView> createState() => _SwiperCardViewState();
}

class _SwiperCardViewState extends State<SwiperCardView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(widget.interval, () {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % widget.cards.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.cards.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: widget.cards[index],
        ),
      ),
    );
  }
}
