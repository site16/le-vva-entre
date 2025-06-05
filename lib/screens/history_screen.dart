import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ride_history_entry.dart';
import '../providers/history_provider.dart';
import '../widgets/history_summary_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  static const routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _getFilterButtonText(HistoryProvider provider) {
    final DateFormat btnDateFormat = DateFormat('dd/MM/yy');
    switch (provider.currentFilterType) {
      case HistoryFilterType.all:
        return 'Todos';
      case HistoryFilterType.today:
        return 'Hoje';
      case HistoryFilterType.yesterday:
        return 'Ontem';
      case HistoryFilterType.customRange:
        if (provider.selectedDateRange != null) {
          return '${btnDateFormat.format(provider.selectedDateRange!.start)} - ${btnDateFormat.format(provider.selectedDateRange!.end)}';
        }
        return 'Intervalo';
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
                    initialDateRange: provider.selectedDateRange ?? DateTimeRange(
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

  String _getShortMonth(int month) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return months[month - 1];
  }

  void _showOrderSummarySheet(BuildContext context, RideHistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => HistorySummarySheet(entry: entry),
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
            label: Text(_getFilterButtonText(historyProvider)),
            onPressed: () => _showFilterOptions(context, historyProvider),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(
                            groupTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        ...entriesInGroup.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
                            child: _buildOrderCard(context, entry),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildOrderCard(BuildContext context, RideHistoryEntry entry) {
    final date = entry.dateTime;
    final String day = date.day.toString().padLeft(2, '0');
    final String month = _getShortMonth(date.month);
    final String paymentValue = "R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}";
    final String orderCode = entry.code ?? "#00000000";
    final String user = entry.userName ?? "@usuário";
    final String timeStart = entry.timeStart ?? '--:--';
    final String timeAccepted = entry.timeAccepted ?? '--:--';
    final String timeDelivered = entry.timeDelivered ?? '--:--';

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showOrderSummarySheet(context, entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data + Valor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$day/$month",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    paymentValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 18,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              // Código do pedido + tipo
              Row(
                children: [
                  Icon(entry.iconData, color: Colors.black54, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "$orderCode",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '- ${entry.typeName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        fontSize: 15,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              // Nome do usuário
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  user,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              // Status + Horários
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.bookmark_border, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(timeStart, style: const TextStyle(color: Colors.black87, fontSize: 13.5)),
                  const SizedBox(width: 16),
                  Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(timeAccepted, style: const TextStyle(color: Colors.black87, fontSize: 13.5)),
                  const SizedBox(width: 16),
                  Icon(Icons.directions_bike, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(timeDelivered, style: const TextStyle(color: Colors.black87, fontSize: 13.5)),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      entry.statusName,
                      style: TextStyle(
                        color: entry.getStatusColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  entry.notes!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}