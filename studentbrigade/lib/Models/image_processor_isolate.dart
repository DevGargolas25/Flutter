import 'dart:isolate';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Datos para procesar imágenes en el Isolate
class ImageProcessingData {
  final String imageUrl;
  final String newsId;
  final int targetWidth;
  final int targetHeight;
  final int quality;
  final SendPort responsePort;

  const ImageProcessingData({
    required this.imageUrl,
    required this.newsId,
    required this.targetWidth,
    required this.targetHeight,
    this.quality = 85,
    required this.responsePort,
  });

  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'newsId': newsId,
    'targetWidth': targetWidth,
    'targetHeight': targetHeight,
    'quality': quality,
  };

  factory ImageProcessingData.fromJson(Map<String, dynamic> json) =>
      ImageProcessingData(
        imageUrl: json['imageUrl'],
        newsId: json['newsId'],
        targetWidth: json['targetWidth'],
        targetHeight: json['targetHeight'],
        quality: json['quality'] ?? 85,
        responsePort: json['responsePort'],
      );
}

/// Resultado del procesamiento de imagen
class ImageProcessingResult {
  final String newsId;
  final String imageUrl;
  final String? processedImagePath;
  final bool success;
  final String? error;
  final int originalSize;
  final int processedSize;
  final Duration processingTime;

  const ImageProcessingResult({
    required this.newsId,
    required this.imageUrl,
    this.processedImagePath,
    required this.success,
    this.error,
    this.originalSize = 0,
    this.processedSize = 0,
    required this.processingTime,
  });

  Map<String, dynamic> toJson() => {
    'newsId': newsId,
    'imageUrl': imageUrl,
    'processedImagePath': processedImagePath,
    'success': success,
    'error': error,
    'originalSize': originalSize,
    'processedSize': processedSize,
    'processingTimeMs': processingTime.inMilliseconds,
  };

  factory ImageProcessingResult.fromJson(Map<String, dynamic> json) =>
      ImageProcessingResult(
        newsId: json['newsId'],
        imageUrl: json['imageUrl'],
        processedImagePath: json['processedImagePath'],
        success: json['success'],
        error: json['error'],
        originalSize: json['originalSize'] ?? 0,
        processedSize: json['processedSize'] ?? 0,
        processingTime: Duration(milliseconds: json['processingTimeMs'] ?? 0),
      );
}

/// Manager principal para procesamiento de imágenes con Isolates
class ImageProcessorIsolate {
  static ImageProcessorIsolate? _instance;
  static ImageProcessorIsolate get instance =>
      _instance ??= ImageProcessorIsolate._();

  ImageProcessorIsolate._();

  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  bool _isInitialized = false;
  final Map<String, Completer<ImageProcessingResult>> _pendingRequests = {};

  /// Inicializa el Isolate de procesamiento de imágenes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Inicializando ImageProcessorIsolate...');

      _receivePort = ReceivePort();

      // Spawn del Isolate
      _isolate = await Isolate.spawn(
        _imageProcessingIsolateEntry,
        _receivePort!.sendPort,
      );

      // Escuchar respuestas del Isolate
      _receivePort!.listen(_handleIsolateResponse);

      // Esperar a que el Isolate esté listo
      await _waitForIsolateReady();

      _isInitialized = true;
      debugPrint('✅ ImageProcessorIsolate inicializado exitosamente');
    } catch (e) {
      debugPrint('❌ Error inicializando ImageProcessorIsolate: $e');
      await dispose();
      rethrow;
    }
  }

  /// Espera a que el Isolate envíe su SendPort
  Future<void> _waitForIsolateReady() async {
    final completer = Completer<SendPort>();

    late StreamSubscription<dynamic> subscription;
    subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        subscription.cancel();
        completer.complete(message);
      }
    });

    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Isolate no respondió'),
    );
  }

  /// Maneja las respuestas del Isolate
  void _handleIsolateResponse(dynamic message) {
    if (message is SendPort) {
      // Ya manejado en _waitForIsolateReady
      return;
    }

    if (message is Map<String, dynamic>) {
      try {
        final result = ImageProcessingResult.fromJson(message);
        final completer = _pendingRequests.remove(result.newsId);

        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
        }

        debugPrint(
          '📸 Imagen procesada: ${result.newsId} (${result.success ? "✅" : "❌"})',
        );
      } catch (e) {
        debugPrint('❌ Error procesando respuesta del Isolate: $e');
      }
    }
  }

  /// Procesa una imagen de noticia en el Isolate
  Future<ImageProcessingResult> processNewsImage(
    String imageUrl,
    String newsId, {
    int targetWidth = 400,
    int targetHeight = 300,
    int quality = 85,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_sendPort == null) {
      throw Exception('Isolate no está disponible');
    }

    try {
      debugPrint('📸 Procesando imagen para noticia: $newsId');

      final completer = Completer<ImageProcessingResult>();
      _pendingRequests[newsId] = completer;

      // Crear ReceivePort para esta solicitud específica
      final responsePort = ReceivePort();
      late StreamSubscription<dynamic> subscription;

      subscription = responsePort.listen((message) {
        if (message is Map<String, dynamic>) {
          try {
            final result = ImageProcessingResult.fromJson(message);
            subscription.cancel();
            responsePort.close();

            if (!completer.isCompleted) {
              completer.complete(result);
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          }
        }
      });

      final data = ImageProcessingData(
        imageUrl: imageUrl,
        newsId: newsId,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        quality: quality,
        responsePort: responsePort.sendPort,
      );

      _sendPort!.send(data.toJson()..['responsePort'] = responsePort.sendPort);

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          subscription.cancel();
          responsePort.close();
          _pendingRequests.remove(newsId);
          return ImageProcessingResult(
            newsId: newsId,
            imageUrl: imageUrl,
            success: false,
            error: 'Timeout procesando imagen',
            processingTime: const Duration(seconds: 30),
          );
        },
      );
    } catch (e) {
      _pendingRequests.remove(newsId);
      debugPrint('❌ Error procesando imagen: $e');
      return ImageProcessingResult(
        newsId: newsId,
        imageUrl: imageUrl,
        success: false,
        error: e.toString(),
        processingTime: Duration.zero,
      );
    }
  }

  /// Procesa múltiples imágenes en paralelo
  Future<List<ImageProcessingResult>> processMultipleImages(
    List<Map<String, dynamic>> imageRequests,
  ) async {
    final futures = imageRequests.map((request) {
      return processNewsImage(
        request['imageUrl'],
        request['newsId'],
        targetWidth: request['targetWidth'] ?? 400,
        targetHeight: request['targetHeight'] ?? 300,
        quality: request['quality'] ?? 85,
      );
    }).toList();

    return await Future.wait(futures);
  }

  /// Obtiene estadísticas del procesamiento
  Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'pending_requests': _pendingRequests.length,
      'isolate_active': _isolate != null,
    };
  }

  /// Dispone del Isolate y libera recursos
  Future<void> dispose() async {
    try {
      _isInitialized = false;

      // Completar requests pendientes con error
      for (final completer in _pendingRequests.values) {
        if (!completer.isCompleted) {
          completer.completeError('Isolate disposed');
        }
      }
      _pendingRequests.clear();

      _receivePort?.close();
      _isolate?.kill(priority: Isolate.immediate);

      _receivePort = null;
      _sendPort = null;
      _isolate = null;

      debugPrint('🗑️ ImageProcessorIsolate disposed');
    } catch (e) {
      debugPrint('❌ Error disposing ImageProcessorIsolate: $e');
    }
  }
}

/// Punto de entrada del Isolate de procesamiento de imágenes
void _imageProcessingIsolateEntry(SendPort mainSendPort) async {
  final receivePort = ReceivePort();

  // Enviar el SendPort al hilo principal
  mainSendPort.send(receivePort.sendPort);

  debugPrint('🔧 Isolate de procesamiento de imágenes iniciado');

  await for (final message in receivePort) {
    if (message is Map<String, dynamic>) {
      try {
        await _processImageInIsolate(message);
      } catch (e) {
        debugPrint('❌ Error en Isolate procesando imagen: $e');

        final responsePort = message['responsePort'] as SendPort?;
        responsePort?.send({
          'newsId': message['newsId'],
          'imageUrl': message['imageUrl'],
          'success': false,
          'error': e.toString(),
          'processingTimeMs': 0,
        });
      }
    }
  }
}

/// Procesa una imagen dentro del Isolate
Future<void> _processImageInIsolate(Map<String, dynamic> data) async {
  final startTime = DateTime.now();
  final responsePort = data['responsePort'] as SendPort;

  try {
    debugPrint('📸 Isolate: Procesando imagen ${data['newsId']}');

    // 1. Descargar imagen
    final response = await http.get(Uri.parse(data['imageUrl']));
    if (response.statusCode != 200) {
      throw Exception('Error descargando imagen: ${response.statusCode}');
    }

    final originalBytes = response.bodyBytes;
    final originalSize = originalBytes.length;

    // 2. Procesar imagen (aquí simularemos el redimensionado)
    // En una implementación real, usarías una librería como 'image'
    final processedBytes = await _resizeImage(
      originalBytes,
      data['targetWidth'],
      data['targetHeight'],
      data['quality'],
    );

    // 3. Guardar imagen procesada en cache
    final cacheKey =
        'processed_${data['newsId']}_${data['targetWidth']}x${data['targetHeight']}';

    // Simular guardado (en implementación real guardarías el archivo)
    await Future.delayed(const Duration(milliseconds: 100));

    final processingTime = DateTime.now().difference(startTime);

    responsePort.send({
      'newsId': data['newsId'],
      'imageUrl': data['imageUrl'],
      'processedImagePath': '/cache/$cacheKey.webp',
      'success': true,
      'originalSize': originalSize,
      'processedSize': processedBytes.length,
      'processingTimeMs': processingTime.inMilliseconds,
    });

    debugPrint(
      '✅ Isolate: Imagen procesada ${data['newsId']} en ${processingTime.inMilliseconds}ms',
    );
  } catch (e) {
    final processingTime = DateTime.now().difference(startTime);

    responsePort.send({
      'newsId': data['newsId'],
      'imageUrl': data['imageUrl'],
      'success': false,
      'error': e.toString(),
      'processingTimeMs': processingTime.inMilliseconds,
    });
  }
}

/// Simula el redimensionado de imagen (placeholder)
Future<Uint8List> _resizeImage(
  Uint8List originalBytes,
  int targetWidth,
  int targetHeight,
  int quality,
) async {
  // Simular procesamiento intensivo
  await Future.delayed(const Duration(milliseconds: 200));

  // En una implementación real, usarías:
  // - package:image para redimensionar
  // - Compresión WebP o JPEG
  // - Optimizaciones de calidad

  // Por ahora retornamos los bytes originales (simulación)
  return originalBytes;
}
