import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/config_provider.dart';
import '../../../core/models/museum_config.dart';

class AdminConfigScreen extends ConsumerStatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  ConsumerState<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends ConsumerState<AdminConfigScreen> {
  final _reasonController = TextEditingController();
  final _capacityController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(configProvider);
    final config = configState.config;

    if (configState.isLoading || config == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN: Control del Museo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, 'ESTADO GLOBAL', Icons.settings_input_component),
            _buildGlobalToggle(theme, config),
            const SizedBox(height: 32),
            
            _buildSectionHeader(theme, 'AFORO MÁXIMO', Icons.people_alt_outlined),
            _buildCapacitySlider(theme, config),
            const SizedBox(height: 32),
            
            _buildSectionHeader(theme, 'CALENDARIO Y EXCEPCIONES', Icons.calendar_month),
            _buildCalendarOverrides(theme, config),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildGlobalToggle(ThemeData theme, MuseumConfig config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.isGlobalOpen ? 'MUSEO ABIERTO' : 'MUSEO CERRADO', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: config.isGlobalOpen ? Colors.green : Colors.red)),
              const Text('Control maestro de disponibilidad', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          Switch(
            value: config.isGlobalOpen,
            onChanged: (val) => ref.read(configProvider.notifier).toggleGlobalOpen(val),
          ),
        ],
      ),
    );
  }

  Widget _buildCapacitySlider(ThemeData theme, MuseumConfig config) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Capacidad Diaria', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${config.maxDailyCapacity} pers.', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          Slider(
            value: config.maxDailyCapacity.toDouble(),
            min: 10,
            max: 500,
            divisions: 49,
            label: config.maxDailyCapacity.toString(),
            onChanged: (val) => ref.read(configProvider.notifier).updateGlobalCapacity(val.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarOverrides(ThemeData theme, MuseumConfig config) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _showAddOverrideDialog,
          icon: const Icon(Icons.add),
          label: const Text('AÑADIR CIERRE O EVENTO'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 16),
        ...config.calendarOverrides.entries.map((entry) => _buildOverrideItem(theme, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildOverrideItem(ThemeData theme, String date, DayConfig dayConfig) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(_getIconForStatus(dayConfig.status), size: 16, color: _getColorForStatus(dayConfig.status)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(dayConfig.reason ?? dayConfig.status.name, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            onPressed: () => ref.read(configProvider.notifier).removeDayOverride(date),
          ),
        ],
      ),
    );
  }

  void _showAddOverrideDialog() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Configurar Día'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Motivo (ej: Festivo, Evento)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Aforo Especial (Dejar vacío para global)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DayStatus>(
                initialValue: DayStatus.closed,
                items: DayStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                onChanged: (val) {},
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final dateKey = DateFormat('yyyy-MM-dd').format(picked);
                final customCap = int.tryParse(_capacityController.text);
                
                ref.read(configProvider.notifier).setDayOverride(
                  dateKey, 
                  DayConfig(
                    status: DayStatus.closed, 
                    reason: _reasonController.text,
                    customCapacity: customCap,
                  )
                );
                _reasonController.clear();
                _capacityController.clear();
                Navigator.pop(ctx);
              }, 
              child: const Text('Guardar')
            ),
          ],
        ),
      );
    }
  }

  IconData _getIconForStatus(DayStatus status) {
    switch (status) {
      case DayStatus.closed: return Icons.block;
      case DayStatus.fullyBooked: return Icons.people;
      case DayStatus.event: return Icons.star;
      default: return Icons.check_circle;
    }
  }

  Color _getColorForStatus(DayStatus status) {
    switch (status) {
      case DayStatus.closed: return Colors.red;
      case DayStatus.fullyBooked: return Colors.orange;
      case DayStatus.event: return Colors.blue;
      default: return Colors.green;
    }
  }
}
