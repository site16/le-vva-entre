// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ride_history_entry.dart';
import '../providers/history_provider.dart';
import '../models/order_model.dart'; // Para usar OrderStatus e OrderType

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  
  String _getFilterButtonText(HistoryProvider provider) {
    final DateFormat btnDateFormat = DateFormat('dd/MM/yy');
    switch (provider.currentFilterType) { // Agora acessível
      case HistoryFilterType.all:
        return 'Todos';
      case HistoryFilterType.today:
        return 'Hoje';
      case HistoryFilterType.yesterday:
        return 'Ontem';
      case HistoryFilterType.customRange:
        if (provider.selectedDateRange != null) { // Agora acessível
          return '${btnDateFormat.format(provider.selectedDateRange!.start)} - ${btnDateFormat.format(provider.selectedDateRange!.end)}';
        }
        return 'Intervalo';
      default: // Adicionado para garantir que a função sempre retorne String
        return 'Filtrar'; 
    }
  }

  void _showFilterOptions(BuildContext context, HistoryProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtrar Histórico', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(title: const Text('Todos'), onTap: () { provider.applyFilter(HistoryFilterType.all); Navigator.pop(ctx); }),
              ListTile(title: const Text('Hoje'), onTap: () { provider.applyFilter(HistoryFilterType.today); Navigator.pop(ctx); }),
              ListTile(title: const Text('Ontem'), onTap: () { provider.applyFilter(HistoryFilterType.yesterday); Navigator.pop(ctx); }),
              ListTile(
                title: const Text('Selecionar Intervalo...'),
                onTap: () async {
                  Navigator.pop(ctx); 
                  final DateTimeRange? picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: provider.selectedDateRange ?? DateTimeRange( // Agora acessível
                        start: DateTime.now().subtract(const Duration(days: 7)),
                        end: DateTime.now(),
                      ),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)), 
                    locale: const Locale('pt', 'BR'),
                     builder: (context, child) { 
                      return Theme(
                        data: Theme.of(context).copyWith(
                           colorScheme: Theme.of(context).colorScheme.copyWith(
                             primary: Theme.of(context).primaryColor, 
                             onPrimary: Colors.white, 
                           ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    provider.applyFilter(HistoryFilterType.customRange, customRange: picked);
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showHistoryDetailSheet(BuildContext context, RideHistoryEntry entry) {
    final DateFormat timeFormat = DateFormat('HH:mm');
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5, margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(entry.iconData, color: Theme.of(context).primaryColor, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.typeName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Status:', entry.statusName, valueColor: entry.getStatusColor(context), isStatus: true),
                  _buildDetailRow('Data:', dateFormat.format(entry.dateTime)),
                  _buildDetailRow('Hora:', timeFormat.format(entry.dateTime)),
                  const SizedBox(height: 8),
                  _buildDetailRow('Origem:', entry.origin, icon: Icons.trip_origin),
                  _buildDetailRow('Destino:', entry.destination, icon: Icons.place),
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Observações:', entry.notes!, icon: Icons.notes),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isStatus = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: Colors.grey.shade600), const SizedBox(width: 8)],
          Text('$label ', style: TextStyle(color: Colors.grey.shade700, fontSize: 15, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 15,
                fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final groupedEntries = historyProvider.groupedEntries;
    final groupKeys = groupedEntries.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Corridas'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.filter_list_rounded),
            label: Text(_getFilterButtonText(historyProvider)), // Corrigido para funcionar com os getters
            onPressed: () => _showFilterOptions(context, historyProvider),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black,
            ),
          )
        ],
      ),
      body: groupedEntries.isEmpty && historyProvider.currentFilterType != HistoryFilterType.all
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Nenhum chamado encontrado para o filtro selecionado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Colors.grey.shade600, height: 1.5),
                ),
              ),
            )
          : groupedEntries.isEmpty && historyProvider.currentFilterType == HistoryFilterType.all
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 20),
                      Text(
                        'Seu histórico está vazio.',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Suas corridas concluídas ou canceladas aparecerão aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: groupKeys.length,
                itemBuilder: (context, index) {
                  final groupTitle = groupKeys[index];
                  final entriesInGroup = groupedEntries[groupTitle]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                        child: Text(
                          groupTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: entriesInGroup.length,
                        itemBuilder: (ctx, entryIdx) {
                          final entry = entriesInGroup[entryIdx];
                          return _buildHistoryItemCard(context, entry);
                        },
                      ),
                       if (index < groupKeys.length -1) const Divider(height: 20, indent: 16, endIndent: 16),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildHistoryItemCard(BuildContext context, RideHistoryEntry entry) {
    final DateFormat timeFormat = DateFormat('HH:mm');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _showHistoryDetailSheet(context, entry),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    // CORREÇÃO DO withOpacity:
                    backgroundColor: Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
                    child: Icon(entry.iconData, color: Theme.of(context).primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.typeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('dd/MM/yy', 'pt_BR').format(entry.dateTime)} às ${timeFormat.format(entry.dateTime)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildAddressRow(Icons.trip_origin, entry.origin),
              const SizedBox(height: 4),
              _buildAddressRow(Icons.place, entry.destination),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  avatar: Icon(
                    entry.status == OrderStatus.completed ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: Colors.white, size: 16
                  ),
                  label: Text(entry.statusName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 12)),
                  backgroundColor: entry.getStatusColor(context),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildAddressRow(IconData icon, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            address,
            style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}