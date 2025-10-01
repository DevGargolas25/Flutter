import 'package:collection/collection.dart';

class VideoMod {
  final String id;
  final String title;
  final String author;
  final List<String> tags; // ["Emergency", "Safety"]
  final String url; // url del video
  final Duration duration; // 5:24
  final int views; // 2300
  final DateTime publishedAt; // para “2 weeks ago”
  final String thumbnail;
  final String description;
  final int likes;

  const VideoMod({
    required this.id,
    required this.title,
    required this.author,
    required this.tags,
    required this.url,
    required this.duration,
    required this.views,
    required this.publishedAt,
    required this.thumbnail,
    this.description = '',
    this.likes = 0,
  });
  //Datos estáticos de videos
}

class VideosInfo {
  final _videos = <VideoMod>[
    VideoMod(
      id: '1',
      title: 'Campus Emergency Procedures',
      author: 'Student Brigade',
      tags: ['Emergency', 'Safety'],
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      duration: const Duration(minutes: 5, seconds: 24),
      views: 2300,
      publishedAt: DateTime.now().subtract(const Duration(days: 14)),
      thumbnail:
          'https://media.istockphoto.com/id/1413724358/es/vector/icono-de-latido-del-coraz%C3%B3n-sostenido-con-la-mano.jpg?s=612x612&w=0&k=20&c=-BR0SoOf5l6LDN7se-wU5okiFrbqf5zmgmDU7AFoqm0=',
      likes: 120,
      description:
          'Learn the essential emergency procedures to ensure your safety on campus. This video covers evacuation routes, emergency contacts, and safety tips.',
    ),
    VideoMod(
      id: '2',
      title: 'First Aid Basics for Students',
      author: 'Student Brigade',
      tags: ['Medical', 'Training'],
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      duration: const Duration(minutes: 8, seconds: 15),
      views: 1800,
      publishedAt: DateTime.now().subtract(const Duration(days: 30)),
      thumbnail:
          'https://media.istockphoto.com/id/1413724358/es/vector/icono-de-latido-del-coraz%C3%B3n-sostenido-con-la-mano.jpg?s=612x612&w=0&k=20&c=-BR0SoOf5l6LDN7se-wU5okiFrbqf5zmgmDU7AFoqm0=',
      likes: 142,
      description:
          'This video provides a comprehensive overview of basic first aid techniques every student should know. From treating minor injuries to handling emergencies, we cover it all.',
    ),
    VideoMod(
      id: '3',
      title: 'Student Brigade Orientation',
      author: 'Student Brigade',
      tags: ['Safety', 'Training'],
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      duration: const Duration(minutes: 12, seconds: 30),
      views: 954,
      publishedAt: DateTime.now().subtract(const Duration(days: 30)),
      thumbnail:
          'https://media.istockphoto.com/id/1413724358/es/vector/icono-de-latido-del-coraz%C3%B3n-sostenido-con-la-mano.jpg?s=612x612&w=0&k=20&c=-BR0SoOf5l6LDN7se-wU5okiFrbqf5zmgmDU7AFoqm0=',
      likes: 139,
      description:
          'Welcome to Student Brigade! This orientation video will introduce you to our mission, values, and the various programs we offer to ensure student safety and well-being on campus.',
    ),
    VideoMod(
      id: '4',
      title: 'Fire Safety on Campus',
      author: 'Student Brigade',
      tags: ['Safety', 'Energency'],
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
      duration: const Duration(minutes: 6, seconds: 45),
      views: 3100,
      publishedAt: DateTime.now().subtract(const Duration(days: 7)),
      thumbnail:
          'https://media.istockphoto.com/id/1413724358/es/vector/icono-de-latido-del-coraz%C3%B3n-sostenido-con-la-mano.jpg?s=612x612&w=0&k=20&c=-BR0SoOf5l6LDN7se-wU5okiFrbqf5zmgmDU7AFoqm0=',
      likes: 50,
      description:
          'This video focuses on fire safety protocols and prevention measures on campus. Learn how to respond in case of a fire emergency and the importance of fire drills.',
    ),
    VideoMod(
      id: '5',
      title: 'Mental Heatl Resources',
      author: 'Student Brigade',
      tags: ['Medical', 'Campus Guide'],
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
      duration: const Duration(minutes: 9, seconds: 18),
      views: 1200,
      publishedAt: DateTime.now().subtract(const Duration(days: 5)),
      thumbnail:
          'https://media.istockphoto.com/id/1413724358/es/vector/icono-de-latido-del-coraz%C3%B3n-sostenido-con-la-mano.jpg?s=612x612&w=0&k=20&c=-BR0SoOf5l6LDN7se-wU5okiFrbqf5zmgmDU7AFoqm0=',
      likes: 90,
      description:
          'This video highlights the mental health resources available to students on campus. Discover counseling services, support groups, and wellness programs designed to help you maintain your mental well-being.',
    ),
    VideoMod(
      id: '6',
      title: ' Campus Navigation Guide',
      author: 'Student Brigade',
      tags: ['Campus Guide', 'Safety'],
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
      duration: const Duration(minutes: 4, seconds: 52),
      views: 1500,
      publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      thumbnail:
          'https://media.istockphoto.com/id/1413724358/es/vector/icono-de-latido-del-coraz%C3%B3n-sostenido-con-la-mano.jpg?s=612x612&w=0&k=20&c=-BR0SoOf5l6LDN7se-wU5okiFrbqf5zmgmDU7AFoqm0=',
      likes: 250,
      description:
          'This video provides a comprehensive guide to navigating the campus safely and efficiently. Learn about key landmarks, transportation options, and tips for getting around.',
    ),
  ];
  Future<List<VideoMod>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _videos;
  }

  Future<VideoMod?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _videos.firstWhereOrNull((v) => v.id == id);
  }
}
