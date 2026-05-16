import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/shop_provider.dart';
import '../providers/ticket_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin_v2_title'.tr(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            tabs: [
              Tab(icon: const Icon(Icons.analytics_outlined), text: 'admin_v2_stats'.tr()),
              Tab(icon: const Icon(Icons.print), text: 'admin_v2_label_prints'.tr()),
              Tab(
                icon: const Icon(Icons.confirmation_num),
                text: 'admin_v2_label_tickets'.tr(),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsTab(context, ref),
            _buildPrintsTab(context, ref),
            _buildTicketsTab(context, ref),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                // Solo mostramos los botones si estamos en la pestaña de Tickets (índice 2)
                if (tabController.index == 2) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.extended(
                        heroTag: 'sale_btn',
                        onPressed: () => context.push('/admin/sale'),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('NUEVA VENTA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.extended(
                        heroTag: 'scanner_btn',
                        onPressed: () => context.push('/admin/scanner'),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text('admin_scanner_title'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            );
          }
        ),
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);
    final purchasesAsync = ref.watch(purchasesStreamProvider);
    final theme = Theme.of(context);

    return purchasesAsync.when(
      data: (purchases) {
        int totalTickets = 0;
        int totalAudio = 0;
        double totalRevenue = 0;

        for (final p in purchases) {
          // Entradas Generales (buscar ambos nombres posibles)
          totalTickets += (p.items['general_tickets'] as int? ?? 0) + (p.items['general'] as int? ?? 0);
          // Entradas Estudiante (buscar ambos nombres posibles)
          totalTickets += (p.items['student_tickets'] as int? ?? 0) + (p.items['student'] as int? ?? 0);
          // Audioguías (buscar ambos nombres posibles)
          totalAudio += (p.items['audio_guides'] as int? ?? 0) + (p.items['audio'] as int? ?? 0);
          
          totalRevenue += double.tryParse(p.totalAmount) ?? 0;
        }

        final totalPrints = shopState.allRequests.length;
        final pendingPrints = shopState.allRequests.where((r) => r.status == PrintStatus.pendiente).length;
        final processingPrints = shopState.allRequests.where((r) => r.status == PrintStatus.imprimiendo || r.status == PrintStatus.enCura).length;
        final finishedPrints = shopState.allRequests.where((r) => r.status == PrintStatus.listo).length;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Resumen de Operaciones', style: theme.textTheme.displayMedium?.copyWith(fontSize: 18)),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard(context, 'Entradas', totalTickets.toString(), Icons.confirmation_num, theme.colorScheme.primary),
                _buildStatCard(context, 'Audio Guías', totalAudio.toString(), Icons.headset_mic, Colors.purpleAccent),
                _buildStatCard(context, 'Impresiones', totalPrints.toString(), Icons.print, Colors.blue),
                _buildStatCard(context, 'Ingresos', '${totalRevenue.toStringAsFixed(0)}€', Icons.euro_symbol, Colors.green),
              ],
            ),
            const SizedBox(height: 32),
            Text('Estado de Producción 3D', style: theme.textTheme.displayMedium?.copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            _buildProgressStat(context, 'Pendientes', pendingPrints, totalPrints, Colors.orange),
            _buildProgressStat(context, 'En Proceso', processingPrints, totalPrints, Colors.blue),
            _buildProgressStat(context, 'Completadas', finishedPrints, totalPrints, Colors.green),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.displayLarge?.copyWith(fontSize: 32, color: color)),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProgressStat(BuildContext context, String label, int count, int total, Color color) {
    final double percent = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintsTab(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopProvider);
    if (state.allRequests.isEmpty) {
      return Center(child: Text('admin_v2_no_prints'.tr()));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.allRequests.length,
      itemBuilder: (context, index) {
        final req = state.allRequests[index];
        return _buildAdminOrderCard(context, ref, req);
      },
    );
  }

  Widget _buildTicketsTab(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final theme = Theme.of(context);

    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return Center(child: Text('admin_v2_no_tickets'.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.qr_code_2, color: theme.colorScheme.primary),
                ),
                title: Text(
                  ticket.visitorName.isEmpty ? 'tickets_visitor_anonymous'.tr() : ticket.visitorName,
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 16),
                ),
                subtitle: Text(
                  '${ticket.visitorEmail}\nEmisión: ${ticket.purchaseDate.day}/${ticket.purchaseDate.month}/${ticket.purchaseDate.year}',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'admin_v2_visit_date_label'.tr(),
                      style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    ),
                    Text(
                      ticket.visitDate.isEmpty ? 'tickets_status_pending'.tr() : ticket.visitDate,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        debugPrint('Error en Tickets Tab: $err');
        return Center(child: Text('Error: $err'));
      },
    );
  }

  Widget _buildAdminOrderCard(
    BuildContext context,
    WidgetRef ref,
    PrintRequest req,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: req.itemImageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(Icons.print, color: theme.colorScheme.primary),
              ),
            ),
            title: Text(
              req.pieceName,
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 16),
            ),
            subtitle: Text(
              'De: ${req.userEmail}\n${req.timestamp.toString().substring(0, 16)}',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 11),
            ),
            trailing: _buildStatusChip(req.status),
          ),
          if (req.notes != null && req.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'admin_v2_notes'.tr(args: [req.notes!]),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(req.stlUrl),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('admin_v2_stl_download'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                PopupMenuButton<PrintStatus>(
                  onSelected: (status) => ref
                      .read(shopProvider.notifier)
                      .updateStatus(req.id, status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'admin_v2_change_status'.tr(),
                          style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => PrintStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(status.name.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(PrintStatus status) {
    Color color;
    switch (status) {
      case PrintStatus.pendiente:
        color = Colors.orange;
        break;
      case PrintStatus.enCura:
        color = Colors.blue;
        break;
      case PrintStatus.imprimiendo:
        color = Colors.purple;
        break;
      case PrintStatus.listo:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        'admin_v2_status_${status.name}'.tr().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
