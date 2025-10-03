import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../VM/Adapter.dart';

class TestFirebasePage extends StatefulWidget {
  static const routeName = '/test-firebase';
  
  @override
  _TestFirebasePageState createState() => _TestFirebasePageState();
}

class _TestFirebasePageState extends State<TestFirebasePage> {
  String _status = "Sin probar";
  String _data = "No hay datos";
  bool _isLoading = false;
  final Adapter _adapter = Adapter();

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = "Probando conexión...";
    });

    try {
      final isConnected = await _adapter.testConnection();
      setState(() {
        _status = isConnected ? "✅ CONECTADO A REALTIME DATABASE" : "❌ NO CONECTADO";
      });
    } catch (e) {
      setState(() {
        _status = "❌ ERROR: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _status = "Cargando usuarios...";
    });

    try {
      final users = await _adapter.getCollection('User');
      String userInfo = "👥 USUARIOS (${users.length}):\n\n";
      
      for (var user in users) {
        userInfo += "📄 ${user['id']}: ${user['fullName']} (${user['userType']})\n";
      }
      
      setState(() {
        _data = userInfo;
        _status = "✅ Usuarios cargados";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error cargando usuarios: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _status = "Cargando videos...";
    });
  
    try {
      final videos = await _adapter.getVideos(); // ← Ahora devuelve List<VideoMod>
      String videoInfo = "🎥 VIDEOS (${videos.length}):\n\n";
      
      for (var video in videos) {
        videoInfo += "📹 ${video.title}\n";
        videoInfo += "   👨‍💼 Por: ${video.author}\n";
        videoInfo += "   ⏱️ Duración: ${video.duration.inMinutes}:${(video.duration.inSeconds % 60).toString().padLeft(2, '0')}\n";
        videoInfo += "   👁️ ${video.views} views, 👍 ${video.likes} likes\n";
        videoInfo += "   🏷️ Tags: ${video.tags.join(', ')}\n";
        videoInfo += "   📅 ${video.publishedAt.day}/${video.publishedAt.month}/${video.publishedAt.year}\n\n";
      }
      
      setState(() {
        _data = videoInfo;
        _status = "✅ Videos cargados como objetos VideoMod";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error cargando videos: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadBrigadiers() async {
    setState(() {
      _isLoading = true;
      _status = "Cargando brigadistas...";
    });

    try {
      final brigadiers = await _adapter.getAllBrigadiers();
      String brigInfo = " BRIGADISTAS (${brigadiers.length}):\n\n";
      
      for (var brig in brigadiers) {
        brigInfo += "‍⚕️ ${brig['fullName']}\n";
        brigInfo += "   📍 ${brig['latitude']}, ${brig['longitude']}\n";
        brigInfo += "   📊 Status: ${brig['status']}\n\n";
      }
      
      setState(() {
        _data = brigInfo;
        _status = "✅ Brigadistas cargados";
      });
    } catch (e) {
      setState(() {
        _status = "❌ Error cargando brigadistas: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Realtime Database')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Text('Estado: $_status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            SizedBox(height: 20),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: Icon(Icons.wifi_find),
                  label: Text('Conectar'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadUsers,
                  icon: Icon(Icons.people),
                  label: Text('Usuarios'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadVideos,
                  icon: Icon(Icons.video_library),
                  label: Text('Videos'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadBrigadiers,
                  icon: Icon(Icons.local_hospital),
                  label: Text('Brigadistas'),
                ),
              ],
            ),
            
            if (_isLoading) ...[
              SizedBox(height: 20),
              Center(child: CircularProgressIndicator()),
            ],
            
            SizedBox(height: 24),
            
            Text('Resultados:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(_data, style: TextStyle(fontFamily: 'monospace')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}