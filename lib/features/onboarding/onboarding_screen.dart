import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../routing/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatController;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Sua Jornada Literária',
      'description': 'Organize suas leituras, registre seu progresso e redescubra o prazer de terminar um livro.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA932-2dM34fN-ZK7MimO0gy19LnMmY_606CcW5uXENCwbRCtVaLF6yYs1gRfrOUh-IHFpIRERPhvxQpr69UNlrlYAMRXmZ7n3YirzVcWOlHwaF0QY05A4Iew6BdIPO7tKlwI5eb9ZuFjDQCNf5okDuUmB2OZxgTXZ38SsimBevGpNvK8qpxKCkYE1h1PwIC62r7IaubJ6OJi2K-pAHCrsGKZDpZTceqAppgo_YWoowcU6L068XjPW7_GzA37ND0S57NB_SJgB_6Bk',
    },
    {
      'title': 'O Círculo de Leitores',
      'description': 'Conecte-se com amigos, compartilhe recomendações e veja o que sua comunidade está lendo em tempo real.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCV-G0mZBl4ieN9FxBEar2Ehma4ljF4NUbc6eGOPSlovbiZjXGva0vCTZFXUkFFbs8JHhEZ-cprRCzX3nVZTW1b0JSTLrF7KMv8N7siBw2h6h6X4i3fF90Lf3uyoSjdKoLGzbqnioPBFuD5iqzHDrMZqrzu7AqGbx-6Dc1Lm50938jQJZFqsFoUnu1hxRAbUxfYA_nel-LVWwx5CtODc9PU4SPSU4oyIS8FQBD1B-UPlQ0B7GJ5nILvXkv9O7Ie4X_IieY-eRORSpQ',
    },
    {
      'title': 'Garimpo de Tesouros',
      'description': 'Encontre edições raras, livros assinados e usados diretamente da estante de outros leitores apaixonados.',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDSjHNhMrBPdlQdKE2_vCU7wpAVFXQyG_TDN8zs8Epf5_scUyzrtbUihkV8XiTEc_JJL1LNAVf6oia_dQCc5VQSeZnaftC1SEfVVvwctB5pqagLWLzhRWvXK78O0wjkoUNA8zFlEHIyiX0r9ZWHfU5iZtaZNowsu0GnJxJo9dUEC24r06iKOAHwAgYvJmsUxda9eLLWzyySbjFibGQSaDUvd7Bvm9cVeH3S1Sn9lSbzTiUN7uELSE7tBbhyGV2rL1S-AxyO6n3QBoI',
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _complete(BuildContext context) async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Main Page Content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bibliotheca',
                        style: GoogleFonts.literata(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (_currentPage < 2)
                        TextButton(
                          onPressed: () => _complete(context),
                          child: Text(
                            'Pular',
                            style: AppTheme.labelSans.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48), // Spacing placeholder
                    ],
                  ),
                ),

                // Sliding Presentation Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _buildPageContent(page, index);
                    },
                  ),
                ),

                // Bottom Controls Wrapper
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPageContent(Map<String, String> page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.marginMobile),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gentle floating container for the 3D illustration
          Flexible(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final translation = Offset(0, -12 * _floatController.value);
                return Transform.translate(
                  offset: translation,
                  child: child,
                );
              },
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280, maxWidth: 280),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: page['imageUrl']!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceLow,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surfaceLow,
                      child: const Icon(Icons.image, size: 64, color: AppTheme.outline),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final page = _pages[_currentPage];
    final isPage2 = _currentPage == 1;
    final isLastPage = _currentPage == 2;

    Widget typographyAndButtonsContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pages.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 24 : 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isActive ? AppTheme.primary : AppTheme.outlineVariant,
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Title (Literata Serif)
        Text(
          page['title']!,
          textAlign: TextAlign.center,
          style: GoogleFonts.literata(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Description (Plus Jakarta Sans)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            page['description']!,
            textAlign: TextAlign.center,
            style: AppTheme.bodySans.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Main CTA Button
        FilledButton(
          onPressed: () {
            if (isLastPage) {
              _complete(context);
            } else {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          },
          child: isLastPage
              ? const Text('Começar')
              : (isPage2
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Próximo'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    )
                  : const Text('Próximo')),
        ),

        // Secondary link for Page 3 (Login)
        if (isLastPage) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              await _complete(context);
              if (mounted) context.push('/entrar');
            },
            child: Text.rich(
              TextSpan(
                text: 'Já possui uma conta? ',
                style: AppTheme.captionSans.copyWith(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                children: [
                  TextSpan(
                    text: 'Fazer Login',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );

    // Page 2 utilizes the custom rounded semi-transparent Card design from the HTML
    if (isPage2) {
      return Container(
        margin: const EdgeInsets.all(AppTheme.marginMobile),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: typographyAndButtonsContent,
      );
    }

    // Default container styling for Page 1 and Page 3
    return Container(
      padding: const EdgeInsets.all(24),
      child: typographyAndButtonsContent,
    );
  }
}
