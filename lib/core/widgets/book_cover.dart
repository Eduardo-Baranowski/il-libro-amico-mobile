import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    this.url,
    this.width = 56,
    this.height = 72,
    this.borderRadius = 2,
  });

  final String? url;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    final iconSize = (width < height ? width : height) * 0.38;
    return Container(
      color: AppTheme.primarySoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_rounded,
        color: AppTheme.primary,
        size: iconSize.clamp(14, 32),
      ),
    );
  }
}

/// Fundo do header de detalhe do livro: blur só quando a capa carrega com sucesso.
class BookCoverHeaderBackground extends StatelessWidget {
  const BookCoverHeaderBackground({
    super.key,
    this.url,
    this.height = 250,
    this.blurSigma = 16,
  });

  final String? url;
  final double height;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: url != null && url!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: height,
              placeholder: (_, __) => _fallback(),
              errorWidget: (_, __, ___) => _fallback(),
              imageBuilder: (context, imageProvider) => ClipRect(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: height,
                  ),
                ),
              ),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primarySoft,
            AppTheme.surfaceContainer,
            AppTheme.secondaryContainer,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, right: 12),
          child: Icon(
            Icons.menu_book_rounded,
            size: 110,
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.url,
    this.name = '',
    this.radius = 22,
  });

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(url!),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.secondaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          color: AppTheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
