import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Caches/video_cache_manager.dart';

class CachedVideoThumbnail extends StatelessWidget {
  final String videoId;
  final String thumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CachedVideoThumbnail({
    super.key,
    required this.videoId,
    required this.thumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: VideoCacheManager().getCachedThumbnail(
        videoId,
      ), // ← FIX: usar videoId, no thumbnailUrl
      builder: (context, snapshot) {
        // Si tenemos el thumbnail en cache, usarlo
        if (snapshot.hasData && snapshot.data != null) {
          final cachedFile = snapshot.data!;
          if (cachedFile.existsSync()) {
            return Image.file(
              cachedFile,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackThumbnail(context);
              },
            );
          }
        }

        // Si no hay cache, usar CachedNetworkImage que manejará el cache automáticamente
        return CachedNetworkImage(
          imageUrl: thumbnailUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) =>
              _buildFallbackThumbnail(context),
        );
      },
    );
  }

  Widget _buildFallbackThumbnail(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.video_library_outlined,
        size: 32,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}
