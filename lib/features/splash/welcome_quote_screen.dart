import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/reader_repository.dart';

class WelcomeQuoteScreen extends ConsumerStatefulWidget {
  const WelcomeQuoteScreen({super.key});

  @override
  ConsumerState<WelcomeQuoteScreen> createState() => _WelcomeQuoteScreenState();
}

class _WelcomeQuoteScreenState extends ConsumerState<WelcomeQuoteScreen> {
  String _quote = 'A Arte de Viver Mil Vidas';
  String _author = 'Jay Kristoff';

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    try {
      final res = await ref.read(readerRepositoryProvider).randomQuote();
      if (mounted) {
        setState(() {
          _quote = res['quote'] ?? 'A Arte de Viver Mil Vidas';
          _author = res['author'] ?? 'Jay Kristoff';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quote = 'A Arte de Viver Mil Vidas';
          _author = 'Jay Kristoff';
        });
      }
    }
  }

  void _proceed() {
    context.go('/');
  }

  void _shareQuote() {
    Share.share('"$_quote" — $_author');
  }

  @override
  Widget build(BuildContext context) {
    const brandPrimary = Color(0xFFC36A4F);

    return Scaffold(
      backgroundColor: brandPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Subtle Flourishes (Circular Outlines)
          Positioned(
            top: -96,
            left: -96,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 40,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -192,
            right: -192,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 60,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Brand Identity Logo Section
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 96,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Quote / Slogan Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -28,
                          top: -4,
                          child: Icon(
                            Icons.format_quote_rounded,
                            size: 28,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _quote,
                              style: GoogleFonts.literata(
                                fontSize: 24,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                                height: 1.45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _author.toUpperCase(),
                              style: AppTheme.labelSans.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Primary Button: Continuar
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _proceed,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: brandPrimary,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continuar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Secondary Button: Compartilhar
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _shareQuote,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Compartilhar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
