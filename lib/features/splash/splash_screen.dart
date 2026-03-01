import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 아이콘 fade + scale
  late final AnimationController _iconController;
  late final Animation<double> _iconFade;
  late final Animation<double> _iconScale;

  // 텍스트 fade + slide
  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // 로딩 점 3개
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // 아이콘: 0.8초 동안 fade in + scale
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconFade = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeIn,
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );

    // 텍스트: 0.6초 동안 fade in + slide up (0.4초 딜레이)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // 로딩 점: 반복 애니메이션 (1.2초 주기)
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // 순차 실행
    _runAnimations();
  }

  Future<void> _runAnimations() async {
    // 아이콘 시작
    await _iconController.forward();
    // 0.1초 후 텍스트 시작
    await Future.delayed(const Duration(milliseconds: 100));
    await _textController.forward();
    // 1.5초 후 홈으로 이동
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF142F4C);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            ScaleTransition(
              scale: _iconScale,
              child: FadeTransition(
                opacity: _iconFade,
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 앱 이름
            SlideTransition(
              position: _textSlide,
              child: FadeTransition(
                opacity: _textFade,
                child: const Text(
                  'Towa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            // 로딩 점 3개
            FadeTransition(
              opacity: _textFade,
              child: _DotsLoading(controller: _dotsController),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsLoading extends StatelessWidget {
  final AnimationController controller;

  const _DotsLoading({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // 각 점마다 0~0.33, 0.17~0.5, 0.33~0.67 구간에서 fade
        final start = i * 0.25;
        final end = start + 0.5;
        final fade = Tween<double>(begin: 0.2, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeInOut),
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FadeTransition(
            opacity: fade,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
