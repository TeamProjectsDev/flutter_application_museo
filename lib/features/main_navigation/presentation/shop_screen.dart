import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import '../providers/catalog_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  int _generalTickets = 1;
  int _studentTickets = 0;
  int _audioGuides = 0;
  double _printHeight = 50.0;
  bool _include3DPrint = false;
  String? _selectedPiece;

  double get _subtotal {
    return (_generalTickets * 25.0) +
        (_studentTickets * 15.0) +
        (_audioGuides * 8.0) +
        (_include3DPrint ? (10.0 + _printHeight * 0.2) : 0);
  }

  double get _fees => _subtotal * 0.1;
  double get _total => _subtotal + _fees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('shop_plan_visit'.tr(),
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'shop_plan_visit'.tr(),
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'shop_plan_desc'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 40),

              _buildTicketItem(
                title: 'shop_item_general_title'.tr(),
                desc: 'shop_item_general_desc'.tr(),
                price: 25.0,
                quantity: _generalTickets,
                onChanged: (val) {
                  setState(() {
                    _generalTickets = val;
                    // Auto-ajuste de audioguías si superan el nuevo total
                    final maxAllowed = _generalTickets + _studentTickets;
                    if (_audioGuides > maxAllowed) _audioGuides = maxAllowed;
                  });
                },
                isPopular: true,
              ),
              const SizedBox(height: 16),
              _buildTicketItem(
                title: 'shop_item_student_title'.tr(),
                desc: 'shop_item_student_desc'.tr(),
                price: 15.0,
                quantity: _studentTickets,
                onChanged: (val) {
                  setState(() {
                    _studentTickets = val;
                    // Auto-ajuste de audioguías si superan el nuevo total
                    final maxAllowed = _generalTickets + _studentTickets;
                    if (_audioGuides > maxAllowed) _audioGuides = maxAllowed;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTicketItem(
                title: 'shop_item_audio_title'.tr(),
                desc: 'shop_item_audio_desc'.tr(),
                price: 8.0,
                quantity: _audioGuides,
                onChanged: (val) {
                  final maxAllowed = _generalTickets + _studentTickets;
                  if (val <= maxAllowed) {
                    setState(() => _audioGuides = val);
                  }
                },
                icon: Icons.headphones_outlined,
              ),

              const SizedBox(height: 32),
              const Divider(color: Colors.white10),
              const SizedBox(height: 32),

              // 🖨️ 3D Print Service
              _build3DPrintSection(theme),

              const SizedBox(height: 40),

              // 📊 Order Summary
              _buildOrderSummary(theme),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem({
    required String title,
    required String desc,
    required double price,
    required int quantity,
    required Function(int) onChanged,
    bool isPopular = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('MOST POPULAR',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 12)),
                    const SizedBox(height: 16),
                    Text('\$${price.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                        onPressed:
                            quantity > 0 ? () => onChanged(quantity - 1) : null,
                        icon: const Icon(Icons.remove, size: 16)),
                    Text('$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => onChanged(quantity + 1),
                        icon: const Icon(Icons.add, size: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DPrintSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: _include3DPrint,
              onChanged: (val) =>
                  setState(() => _include3DPrint = val ?? false),
              activeColor: theme.colorScheme.primary,
            ),
            Text('shop_3d_print_add'.tr(),
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 18)),
          ],
        ),
        if (_include3DPrint) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final catalogState = ref.watch(catalogProvider);
                    final pieces = catalogState.pieces3D;

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedPiece,
                      decoration: InputDecoration(
                        labelText: 'Selecciona la pieza a imprimir',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.2),
                      ),
                      dropdownColor: theme.colorScheme.surface,
                      items: pieces.map((art) {
                        return DropdownMenuItem(
                          value: art.name,
                          child: Text(art.name,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedPiece = v),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('shop_3d_height_select'.tr()),
                Slider(
                  value: _printHeight,
                  min: 20,
                  max: 200,
                  divisions: 18,
                  label: '${_printHeight.toInt()}mm',
                  onChanged: (v) => setState(() => _printHeight = v),
                ),
                Text('Price: \$${(10 + _printHeight * 0.2).toStringAsFixed(2)}',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('shop_order_summary'.tr(),
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 22)),
          const SizedBox(height: 24),
          if (_generalTickets > 0)
            _summaryRow('${'shop_item_general_title'.tr()} x$_generalTickets',
                _generalTickets * 25.0),
          if (_studentTickets > 0)
            _summaryRow('${'shop_item_student_title'.tr()} x$_studentTickets',
                _studentTickets * 15.0),
          if (_audioGuides > 0)
            _summaryRow('${'shop_item_audio_title'.tr()} x$_audioGuides',
                _audioGuides * 8.0),
          if (_include3DPrint)
            _summaryRow(
                '3D Print (${_selectedPiece ?? 'Pieza'}) ${_printHeight.toInt()}mm',
                10.0 + _printHeight * 0.2),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          _summaryRow('shop_subtotal'.tr(), _subtotal, isSmall: true),
          _summaryRow('shop_fee'.tr(), _fees, isSmall: true),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('shop_total'.tr(), style: const TextStyle(fontSize: 18)),
              Text('\$${_total.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  (_total > 0 && (!_include3DPrint || _selectedPiece != null))
                      ? () => _proceedToCheckout()
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('shop_proceed'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isSmall = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface
                    .withValues(alpha: isSmall ? 0.5 : 0.8),
                fontSize: isSmall ? 12 : 14,
              ),
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isSmall ? 12 : 14,
              fontWeight: isSmall ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    context.push(
      Uri(
        path: '/payment',
        queryParameters: {
          'total': _total.toStringAsFixed(2),
          'subtotal': _subtotal.toStringAsFixed(2),
          'fees': _fees.toStringAsFixed(2),
          'tickets': json.encode({
            'general': _generalTickets,
            'student': _studentTickets,
            'audio': _audioGuides,
            'print': _include3DPrint ? _printHeight.toInt() : 0,
          }),
          if (_include3DPrint && _selectedPiece != null)
            'printPieceName': _selectedPiece!,
        },
      ).toString(),
    );
  }
}
