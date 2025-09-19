class VideoItem {
  final String id;
  final String title;
  final List<String> tags; // p.ej. ["Emergency","Safety"]
  final String channel; // p.ej. "Student Brigade"
  final String views; // p.ej. "2.3k views"
  final String timeAgo; // p.ej. "2 weeks ago"
  final String duration; // "5:24"

  const VideoItem({
    required this.id,
    required this.title,
    required this.tags,
    required this.channel,
    required this.views,
    required this.timeAgo,
    required this.duration,
  });
}
