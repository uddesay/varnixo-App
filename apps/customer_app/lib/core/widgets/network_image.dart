import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'skeleton_loader.dart';

/// Cached product/media image with a shimmer placeholder and a graceful
/// broken-image fallback — every image in the app should go through this
/// rather than raw `Image.network`.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    required this.url,
    super.key,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget image = url == null || url!.isEmpty
        ? _fallback(context)
        : CachedNetworkImage(
            imageUrl: url!,
            fit: fit,
            placeholder: (context, _) =>
                const SkeletonBox(width: double.infinity, height: double.infinity, borderRadius: 0),
            errorWidget: (context, _, __) => _fallback(context),
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _fallback(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}
