import 'package:flutter/material.dart';
import 'package:studentbrigade/VM/Orchestrator.dart';
import 'package:studentbrigade/Models/newsModel.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsScreen extends StatefulWidget {
  final Orchestrator orchestrator;

  const NewsScreen({super.key, required this.orchestrator});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    // Agregar debugging
    print('📱 NewsScreen: Inicializando y cargando noticias...');

    // Primero agregar noticias de prueba si no existen
    _ensureTestData().then((_) {
      // Luego cargar las noticias
      widget.orchestrator.newsVM.loadNews().then((_) {
        print('📱 NewsScreen: Carga de noticias completada');
        print(
          '📱 NewsScreen: Número de noticias: ${widget.orchestrator.newsVM.news.length}',
        );
      });
    });
  }

  Future<void> _ensureTestData() async {
    try {
      print('🧪 NewsScreen: Verificando datos existentes...');

      // Primero verificar si ya hay noticias
      final existingNews = await widget.orchestrator.newsVM.newsService
          .fetchNews();
      if (existingNews.isNotEmpty) {
        print('✅ NewsScreen: Ya existen ${existingNews.length} noticias');
        return;
      }

      print('🧪 NewsScreen: No hay noticias, creando datos de prueba...');

      final testNews1 = NewsModel(
        id: 'test1',
        title: 'University Launches New Biomedical Engineering Program',
        description:
            'The Faculty of Engineering announced a new undergraduate program in Biomedical Engineering that will combine traditional engineering principles with medical sciences.',
        imageUrl:
            'https://images.unsplash.com/photo-1606761568499-6d2451b23c66?q=80&w=1074&auto=format&fit=crop',
        author: 'Dr. Sarah Johnson',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        tags: [
          'university',
          'biomedical engineering',
          'education',
          'innovation',
          'medical technology',
        ],
      );

      final testNews2 = NewsModel(
        id: 'test2',
        title: 'New Research Lab Opens for AI Development',
        description:
            'The university has opened a state-of-the-art AI research laboratory equipped with the latest technology for machine learning and artificial intelligence research.',
        imageUrl:
            'https://images.unsplash.com/photo-1507146426996-ef05306b995a?q=80&w=1170&auto=format&fit=crop',
        author: 'Prof. Michael Chen',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        tags: ['AI', 'research', 'technology', 'laboratory', 'innovation'],
      );

      final newsService = widget.orchestrator.newsVM.newsService;
      await newsService.addNews(testNews1);
      await newsService.addNews(testNews2);

      print('✅ NewsScreen: Datos de prueba agregados');
    } catch (e) {
      print('⚠️ NewsScreen: Error con datos de prueba: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.orchestrator.newsVM.loadMoreNews();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      widget.orchestrator.newsVM.clearSearch();
    } else {
      widget.orchestrator.newsVM.searchNews(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News Feed'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListenableBuilder(
              listenable: _searchController,
              builder: (context, _) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search news...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.orchestrator.newsVM.clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      widget.orchestrator.newsVM.searchNews(query);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mensaje de offline
          if (widget.orchestrator.newsVM.isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No hay conexión. Por favor conéctate a internet para obtener noticias actualizadas.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Contenido principal
          Expanded(
            child: ListenableBuilder(
              listenable: widget.orchestrator.newsVM,
              builder: (context, _) {
                final newsVM = widget.orchestrator.newsVM;

                if (newsVM.isLoading && newsVM.news.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (newsVM.hasError && newsVM.news.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading news',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          newsVM.errorMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => newsVM.loadNews(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (newsVM.news.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.newspaper_outlined, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No news available',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await newsVM.loadNews();
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: newsVM.news.length + (newsVM.hasMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index >= newsVM.news.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final news = newsVM.news[index];
                      return _NewsCard(
                        news: news,
                        onTap: () => _showNewsDetail(context, news),
                      );
                    },
                  ),
                );
              },
            ), // cierre ListenableBuilder
          ), // cierre Expanded
        ],
      ), // cierre Column
    ); // cierre Scaffold
  }

  void _showNewsDetail(BuildContext context, NewsModel news) {
    // Registrar que se abrió la noticia para el LRU
    widget.orchestrator.newsVM.selectNews(news);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewsDetailSheet(news: news),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;

  const _NewsCard({required this.news, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: news.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    news.title,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    news.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  if (news.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: news.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Footer
                  Row(
                    children: [
                      // Author
                      Expanded(
                        child: Text(
                          'By ${news.author}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      // Date
                      Text(
                        _formatDate(news.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _NewsDetailSheet extends StatelessWidget {
  final NewsModel news;

  const _NewsDetailSheet({required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: news.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(news.title, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      // Author and date
                      Row(
                        children: [
                          Text(
                            'By ${news.author}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatDate(news.createdAt),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Description
                      Text(news.description, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 20),
                      // Tags
                      if (news.tags.isNotEmpty) ...[
                        Text('Tags', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: news.tags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hrs ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
