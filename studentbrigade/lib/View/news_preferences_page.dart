import 'package:flutter/material.dart';
import '../Models/news_preferences_service.dart';
import '../VM/Orchestrator.dart';

class NewsPreferencesPage extends StatefulWidget {
  final Orchestrator? orchestrator; // Hacer opcional para compatibilidad

  const NewsPreferencesPage({super.key, this.orchestrator});

  @override
  State<NewsPreferencesPage> createState() => _NewsPreferencesPageState();
}

class _NewsPreferencesPageState extends State<NewsPreferencesPage> {
  final NewsPreferencesService _preferencesService =
      NewsPreferencesService.instance;

  List<String> _availableTags = [];
  Map<String, bool> _tagPreferences = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTagsAndPreferences();
  }

  Future<void> _loadTagsAndPreferences() async {
    setState(() => _isLoading = true);

    try {
      // Obtener las preferencias existentes
      _tagPreferences = await _preferencesService.getTagPreferences();

      // Necesitamos obtener los tags desde el context después de initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAvailableTags();
      });
    } catch (e) {
      debugPrint('❌ Error cargando preferencias: $e');
    }
  }

  void _loadAvailableTags() {
    try {
      // Si tenemos orchestrator, obtener tags reales de las noticias
      if (widget.orchestrator != null) {
        _availableTags = widget.orchestrator!.newsVM.getAllAvailableTags();
        debugPrint('📰 Tags obtenidos del sistema: ${_availableTags.length}');
      }

      // Si no hay tags del sistema o como fallback, usar tags comunes
      if (_availableTags.isEmpty) {
        _availableTags = [
          'university',
          'biomedical engineering',
          'education',
          'innovation',
          'medical technology',
          'AI',
          'research',
          'technology',
          'laboratory',
          'students',
          'science',
          'health',
          'engineering',
          'news',
          'campus',
          'academic',
          'development',
          'future',
          'learning',
          'digital',
        ];
      } // Cerrar el if para fallback

      // Inicializar preferencias para tags que no existen
      for (final tag in _availableTags) {
        if (!_tagPreferences.containsKey(tag)) {
          _tagPreferences[tag] = false;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error cargando tags disponibles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await _preferencesService.saveTagPreferences(_tagPreferences);

      // Si hay orchestrator disponible, aplicar el filtro automáticamente
      if (widget.orchestrator != null) {
        // Activar el filtro por preferencias
        widget.orchestrator!.newsVM.setUsePreferencesFilter(true);
        // Aplicar el filtro con las nuevas preferencias
        await widget.orchestrator!.newsVM.applyPreferencesFilter();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preferencias guardadas exitosamente'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando preferencias: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleTagPreference(String tag, bool value) {
    setState(() {
      _tagPreferences[tag] = value;
    });
  }

  Future<void> _clearAllPreferences() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Preferencias'),
        content: const Text(
          '¿Estás seguro de que quieres limpiar todas las preferencias de tags?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                for (final key in _tagPreferences.keys) {
                  _tagPreferences[key] = false;
                }
              });

              await _savePreferences();
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Preferences News'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final preferredCount = _tagPreferences.values
        .where((value) => value == true)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences News'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _clearAllPreferences,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar todo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Configura tus tags favoritos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las noticias se filtrarán según tus preferencias',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$preferredCount de ${_availableTags.length} tags seleccionados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de tags
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableTags.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tag = _availableTags[index];
                final isPreferred = _tagPreferences[tag] ?? false;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPreferred
                            ? colorScheme.primary.withOpacity(0.1)
                            : colorScheme.outline.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tag,
                        color: isPreferred
                            ? colorScheme.primary
                            : colorScheme.outline,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      tag,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: isPreferred
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isPreferred
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    trailing: Switch(
                      value: isPreferred,
                      onChanged: (value) => _toggleTagPreference(tag, value),
                      activeColor: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Guardar Preferencias',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
