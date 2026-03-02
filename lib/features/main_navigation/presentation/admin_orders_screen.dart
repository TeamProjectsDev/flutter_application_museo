import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/shop_provider.dart';
import '../providers/ticket_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('admin_title'.tr()),
          backgroundColor: Colors.blueGrey.shade900,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: const Icon(Icons.print), text: 'admin_3d_prints'.tr()),
              Tab(
                icon: const Icon(Icons.confirmation_num),
                text: 'admin_tickets'.tr(),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrintsTab(context, ref),
            _buildTicketsTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintsTab(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopProvider);
    return state.allRequests.isEmpty
        ? Center(child: Text('admin_no_prints'.tr()))
        : ListView.builder(
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

    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return Center(child: Text('admin_no_tickets'.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_2, color: Colors.green),
                ),
                title: Text(
                  ticket.visitorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${ticket.visitorEmail}\nEmisión: ${ticket.purchaseDate.day}/${ticket.purchaseDate.month}/${ticket.purchaseDate.year}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'admin_visit_date:',
                      style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                    ),
                    Text(
                      ticket.visitDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
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
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildAdminOrderCard(
    BuildContext context,
    WidgetRef ref,
    PrintRequest req,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                errorWidget: (context, url, error) => const Icon(Icons.print),
              ),
            ),
            title: Text(
              req.itemName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'De: ${req.userEmail}\n${req.timestamp.toString().substring(0, 16)}',
            ),
            trailing: _buildStatusChip(req.status),
          ),
          if (req.notes != null && req.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'admin_notes'.tr(args: [req.notes!]),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                // Acción de descarga STL
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(req.stlUrl),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('admin_stl_download'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),

                // Menú de cambio de estado
                PopupMenuButton<PrintStatus>(
                  onSelected: (status) => ref
                      .read(shopProvider.notifier)
                      .updateStatus(req.id, status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'admin_change_status'.tr(),
                          style: const TextStyle(color: Colors.deepPurple),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => PrintStatus.values
                      .map(
                        (status) => PopupMenuItem(
                          value: status,
                          child: Text(status.name.replaceAll('_', ' ')),
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
      case PrintStatus.en_cura:
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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase().replaceAll('_', ' '),
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
