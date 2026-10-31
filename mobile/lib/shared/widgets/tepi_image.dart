import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tepilog/app/theme.dart';

/// Shows a post photo from wherever it lives: bundled demo asset (`asset:`),
/// a file saved by demo mode (`file:`), or a Cloudinary URL.
class TepiImage extends StatelessWidget {
  const TepiImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('asset:')) {
      return Image.asset(url.substring('asset:'.length), fit: fit);
    }
    if (url.startsWith('file:')) {
      return Image.file(File(url.substring('file:'.length)), fit: fit);
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppTheme.surface,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
