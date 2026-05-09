import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/artifact_details.dart';

class Viewer3DScreen extends StatefulWidget {
  final String? modelFileName;
  final String? room;
  const Viewer3DScreen({super.key, this.modelFileName, this.room});

  @override
  State<Viewer3DScreen> createState() => _Viewer3DScreenState();
}

class _Viewer3DScreenState extends State<Viewer3DScreen> {
  bool _isLoading = true;
  String? _modelUrl;
  late final String _modelFileName;
  late final ArtifactDetail _details;

  @override
  void initState() {
    super.initState();
    String rawModel = widget.modelFileName ?? 'mandibula_hombre.glb';
    if (!rawModel.toLowerCase().endsWith('.glb') && !rawModel.toLowerCase().endsWith('.gltf')) {
      rawModel = '$rawModel.glb';
    }
    _modelFileName = rawModel;
    _details = MuseumArtifactManager.getDetail(_modelFileName, widget.room ?? 'General');
    _setupModel();
  }

  void _setupModel() {
    final baseUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';
    setState(() {
      _modelUrl = '$baseUrl/${Uri.encodeComponent(_modelFileName)}';
    });
    
    // Forzamos una espera mínima de 1.5 segundos para una transición suave
    // y para dar tiempo a la inicialización del motor 3D.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: !isWide ? AppBar(
        title: Text(_details.title, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ) : null,
      body: SafeArea(
        child: isWide ? _buildWideLayout(theme) : _buildMobileLayout(theme),
      ),
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      children: [
        // 🏛️ Panel Izquierdo: Visor 3D
        Expanded(
          flex: 6,
          child: _build3DPanel(theme),
        ),
        // 📜 Panel Derecho: Información
        Expanded(
          flex: 4,
          child: Container(
            color: theme.colorScheme.surface,
            child: _buildInfoPanel(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 400,
            child: _build3DPanel(theme),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildInfoPanel(theme),
        ),
      ],
    );
  }

  Widget _build3DPanel(ThemeData theme) {
    return Stack(
      children: [
        // Visor Principal
        if (_modelUrl != null)
          ModelViewer(
            src: _modelUrl!,
            alt: _details.title,
            ar: true,
            autoRotate: true,
            cameraControls: true,
            backgroundColor: Colors.transparent,
          ),
        
        // Overlay de carga Premium
        if (_isLoading)
          Container(
            color: theme.scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación de carga con branding
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                        ),
                      ),
                      Icon(Icons.view_in_ar, size: 30, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'viewer_loading_title'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'viewer_loading_subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Nombre del artefacto siendo cargado
                  Text(
                    _details.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 🏷️ Badge superior
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.view_in_ar, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('viewer_active'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),

        // 🎮 Controles flotantes inferiores
        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildControlButton(Icons.rotate_left_outlined),
                  _buildDivider(),
                  _buildControlButton(Icons.remove),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.center_focus_strong, size: 20, color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  _buildControlButton(Icons.add),
                  _buildDivider(),
                  _buildControlButton(Icons.rotate_right_outlined),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón Atrás
          InkWell(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text('viewer_back'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Categoría
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.yellow),
                const SizedBox(width: 8),
                Text(_details.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            _details.title,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 36, height: 1.1),
          ),
          const SizedBox(height: 8),
          Text(
            _details.subtitle,
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Descripción e Historia
          Text(
            _details.description,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 20),
          Text(
            _details.history,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 15, height: 1.6),
          ),

          const SizedBox(height: 48),

          // Grid de detalles técnicos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildDetailCard(theme, 'viewer_origin'.tr(), _details.origin, Icons.location_on_outlined),
              _buildDetailCard(theme, 'viewer_material'.tr(), _details.material, Icons.hardware_outlined),
              _buildDetailCard(theme, 'viewer_dimensions'.tr(), _details.dimensions, Icons.square_foot_outlined),
              _buildDetailCard(theme, 'viewer_accession'.tr(), _details.accessionNo, Icons.inventory_2_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon) {
    return IconButton(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white70, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 20,
      width: 1,
      color: Colors.white10,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildDetailCard(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
