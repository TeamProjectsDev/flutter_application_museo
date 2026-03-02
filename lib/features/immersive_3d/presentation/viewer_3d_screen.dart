import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../core/network/download_manager.dart';

class Viewer3DScreen extends StatefulWidget {
  final String? modelFileName;
  const Viewer3DScreen({super.key, this.modelFileName});

  @override
  State<Viewer3DScreen> createState() => _Viewer3DScreenState();
}

class _Viewer3DScreenState extends State<Viewer3DScreen> {
  final DownloadManager _downloadManager = DownloadManager();
  bool _isLoading = true;
  double _downloadProgress = 0.0;
  String? _localModelPath;

  // El nombre del archivo que queremos descargar de GitHub
  late final String _modelFileName;

  @override
  void initState() {
    super.initState();
    _modelFileName = widget.modelFileName ?? 'mandibula hombre.glb';
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
    });

    // Pasamos solo el nombre del archivo, el DownloadManager usará la GITHUB_RAW_URL
    final String? path = await _downloadManager.downloadAndCacheFile(
      _modelFileName,
      _modelFileName,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _downloadProgress = received / total;
          });
        }
      },
    );

    if (mounted) {
      if (path != null) {
        setState(() {
          _localModelPath = path.startsWith('http') ? path : 'file://$path';
          _isLoading = false;
        });
        FirebaseAnalytics.instance.logEvent(
          name: 'view_item_3d',
          parameters: {'item_name': _modelFileName},
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar el modelo de GitHub')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor 3D'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _downloadManager.deleteFromCache(_modelFileName);
              _loadModel();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Preparando sala museo...\n${(_downloadProgress * 100).toStringAsFixed(1)}%',
                  ),
                ],
              ),
            )
          : ModelViewer(
              src: _localModelPath ?? '',
              alt: 'Modelo de GitHub',
              ar: true,
              autoRotate: true,
              cameraControls: true,
            ),
    );
  }
}
