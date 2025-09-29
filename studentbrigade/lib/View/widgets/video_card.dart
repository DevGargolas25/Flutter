import 'package:flutter/material.dart';
import '../video.dart';

class VideoCard extends StatelessWidget {
  final VideoItem video;
  final VoidCallback? onTap;
  const VideoCard({super.key, required this.video, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: radius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (placeholder con ícono y duración)
            Container(
              height: 170,
              width: double.infinity,
              color: const Color(0xFFDFF0F1),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 56,
                      color: Color(0xFF67B7B9),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF3E2B56,
                        ), // morado oscuro como en el mock
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        video.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Descripción
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: radius.topLeft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -6,
                    children: video.tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4F4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: Color(0xFF2D8E90),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        video.channel,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.black26)),
                      const SizedBox(width: 8),
                      Text(
                        video.views,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      const Text('•', style: TextStyle(color: Colors.black26)),
                      const SizedBox(width: 8),
                      Text(
                        video.timeAgo,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
