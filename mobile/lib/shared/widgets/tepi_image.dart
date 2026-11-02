import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tepilog/app/theme.dart';

/// Where a post photo lives: bundled demo asset (`asset:`), a file saved by
/// demo mode (`file:`), or a Cloudinary URL.
ImageProvider tepiImageProvider(String url) {
  if (url.startsWith('asset:')) return AssetImage(url.substring('asset:'.length));
  if (url.startsWith('file:')) return FileImage(File(url.substring('file:'.length)));
  return NetworkImage(url);
}

/// Shows a post photo from any of the sources [tepiImageProvider] knows.
class TepiImage extends StatelessWidget {
  const TepiImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: tepiImageProvider(url),
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
