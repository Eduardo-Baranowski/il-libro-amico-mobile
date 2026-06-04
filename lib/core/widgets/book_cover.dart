import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    this.url,
    this.width = 56,
    this.height = 72,
    this.borderRadius = 12,
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
    return Container(
      color: AppTheme.primarySoft,
      alignment: Alignment.center,
      child: const Icon(Icons.menu_book_rounded, color: AppTheme.primary),
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
      backgroundColor: AppTheme.primarySoft,
      child: Text(
        initial,
        style: TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
