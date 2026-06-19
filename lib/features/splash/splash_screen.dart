import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final List<String> _images = [
    'assets/images/splash/screen.png',
    'assets/images/splash/screen1.png',
    'assets/images/splash/screen3.png',
    'assets/images/splash/screen4.png',
  ];

  int _currentIndex = 0;
  double _progress = 0.0;
  Timer? _imageTimer;
  Timer? _progressTimer;
  
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    // Change image every 1.0 second so we see all 4 images within 4 seconds
    _imageTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) return;
      _fadeController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
        _fadeController.forward();
      });
    });

    // Simulate loading up to 100% over ~4 seconds
    const totalDuration = Duration(milliseconds: 4000);
    const tick = Duration(milliseconds: 40);
    final totalTicks = totalDuration.inMilliseconds / tick.inMilliseconds;
    var currentTick = 0;

    _progressTimer = Timer.periodic(tick, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentTick++;
      setState(() {
        _progress = currentTick / totalTicks;
        if (_progress > 1.0) _progress = 1.0;
      });

      if (_progress >= 1.0) {
        timer.cancel();
        _finishLoading();
      }
    });
  }

  void _finishLoading() {
    if (!mounted) return;
    context.go('/welcome-quote');
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _progressTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parchment background matching the word cloud images
    const parchment = Color(0xFFFBF9F4);
    const terracotta = Color(0xFF93452D);
    const onSurfaceVariant = Color(0xFF55433E);

    return Scaffold(
      backgroundColor: parchment,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with fade transition
          FadeTransition(
            opacity: _fadeController,
            child: Image.asset(
              _images[_currentIndex],
              fit: BoxFit.cover,
            ),
          ),
          
          // Loading UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48.0),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: onSurfaceVariant.withValues(alpha: 0.15),
                    color: terracotta,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: AppTheme.labelSans.copyWith(
                    color: onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

