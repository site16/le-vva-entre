// lib/providers/history_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride_history_entry.dart';
import '../models/order_model.dart';
import './order_provider.dart';

enum HistoryFilterType { all, today, yesterday, customRange }

class HistoryProvider with ChangeNotifier {
  OrderProvider _orderProvider; // Modificado para ser privado e não final

  List<RideHistoryEntry> _allHistoryEntries = [];
  List<RideHistoryEntry> _filteredHistoryEntries = [];

  DateTimeRange? _selectedDateRange;
  HistoryFilterType _currentFilterType = HistoryFilterType.all;

  HistoryProvider(this._orderProvider) { // Recebe a instância inicial
    if (kDebugMode) {
      print("HistoryProvider: Inicializado e ouvindo OrderProvider inicial.");
    }
    _orderProvider.addListener(_updateHistoryFromOrders);
    _updateHistoryFromOrders(); // Carga inicial
  }

  // Getters públicos
  List<RideHistoryEntry> get filteredHistoryEntries => _filteredHistoryEntries;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  HistoryFilterType get currentFilterType => _currentFilterType;

  // Método para atualizar a dependência do OrderProvider
  void updateOrderProvider(OrderProvider newOrderProvider) {
    if (_orderProvider != newOrderProvider) {
      if (kDebugMode) {
        print("HistoryProvider: Atualizando OrderProvider. Removendo listener do antigo, adicionando ao novo.");
      }
      _orderProvider.removeListener(_updateHistoryFromOrders); // Remove do antigo
      _orderProvider = newOrderProvider; // Atualiza para o novo
      _orderProvider.addListener(_updateHistoryFromOrders); // Adiciona ao novo
      _updateHistoryFromOrders(); // Recarrega o histórico com base no novo provider
    }
  }

  void _updateHistoryFromOrders() {
    if (kDebugMode) {
      print("HistoryProvider: _updateHistoryFromOrders chamado. OrderProvider tem ${_orderProvider.orderHistory.length} itens.");
    }
    _allHistoryEntries = _orderProvider.orderHistory.map((order) {
      return RideHistoryEntry(
        id: order.id,
        type: order.type,
        dateTime: order.creationTime, // Idealmente, order.completionTime
        origin: order.pickupAddress,
        destination: order.deliveryAddress,
        value: order.estimatedValue,
        status: order.status,
      );
    }).toList();

    _applyFilterLogic(_currentFilterType, customRange: _selectedDateRange);
    _sortEntries();
    notifyListeners();
  }
  
  void _sortEntries() {
    _filteredHistoryEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Map<String, List<RideHistoryEntry>> get groupedEntries {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final DateFormat groupHeaderFormatThisYear = DateFormat('EEE, dd MMM', 'pt_BR');
    final DateFormat groupHeaderFormatPastYear = DateFormat('dd MMM yy', 'pt_BR');

    Map<String, List<RideHistoryEntry>> map = {};

    for (var entry in _filteredHistoryEntries) {
      String groupKey;
      final entryDate = DateTime(entry.dateTime.year, entry.dateTime.month, entry.dateTime.day);

      if (entryDate.isAtSameMomentAs(today)) {
        groupKey = 'HOJE';
      } else if (entryDate.isAtSameMomentAs(yesterday)) {
        groupKey = 'ONTEM';
      } else if (entryDate.year == now.year) {
        groupKey = groupHeaderFormatThisYear.format(entry.dateTime).toUpperCase();
      } else {
        groupKey = groupHeaderFormatPastYear.format(entry.dateTime).toUpperCase();
      }

      map.putIfAbsent(groupKey, () => []).add(entry);
    }
    return map;
  }

  void _applyFilterLogic(HistoryFilterType filterType, {DateTimeRange? customRange}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = todayEnd.subtract(const Duration(days: 1));

    switch (filterType) {
      case HistoryFilterType.all:
        _filteredHistoryEntries = List.from(_allHistoryEntries);
        break;
      case HistoryFilterType.today:
        _filteredHistoryEntries = _allHistoryEntries.where((entry) {
          return !entry.dateTime.isBefore(todayStart) && !entry.dateTime.isAfter(todayEnd);
        }).toList();
        break;
      case HistoryFilterType.yesterday:
        _filteredHistoryEntries = _allHistoryEntries.where((entry) {
          return !entry.dateTime.isBefore(yesterdayStart) && !entry.dateTime.isAfter(yesterdayEnd);
        }).toList();
        break;
      case HistoryFilterType.customRange:
        if (customRange != null) {
          final rangeStart = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
          final rangeEndInclusive = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999);
          _filteredHistoryEntries = _allHistoryEntries.where((entry) {
            return !entry.dateTime.isBefore(rangeStart) && !entry.dateTime.isAfter(rangeEndInclusive);
          }).toList();
        } else {
            _filteredHistoryEntries = List.from(_allHistoryEntries);
        }
        break;
    }
  }

  void applyFilter(HistoryFilterType filterType, {DateTimeRange? customRange}) {
    _currentFilterType = filterType;
    final now = DateTime.now();
    if (filterType == HistoryFilterType.today) {
        _selectedDateRange = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999));
    } else if (filterType == HistoryFilterType.yesterday) {
        final yesterdayStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        _selectedDateRange = DateTimeRange(start: yesterdayStart, end: DateTime(yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 23, 59, 59, 999));
    } else if (filterType == HistoryFilterType.customRange && customRange != null) {
        _selectedDateRange = customRange;
    } else { // HistoryFilterType.all
        _selectedDateRange = null;
    }

    _applyFilterLogic(filterType, customRange: _selectedDateRange);
    _sortEntries();
    notifyListeners();
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print("HistoryProvider: Disposing and removing listener from OrderProvider.");
    }
    // Remove o listener da instância atual de _orderProvider
    _orderProvider.removeListener(_updateHistoryFromOrders);
    super.dispose();
  }
}