import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride_history_entry.dart';
import './order_provider.dart';
import '../models/order_model.dart';

enum HistoryFilterType { all, today, yesterday, customRange }

class HistoryProvider with ChangeNotifier {
  OrderProvider _orderProvider;

  List<RideHistoryEntry> _allHistoryEntries = [];
  List<RideHistoryEntry> _filteredHistoryEntries = [];

  DateTimeRange? _selectedDateRange;
  HistoryFilterType _currentFilterType = HistoryFilterType.all;

  HistoryProvider(this._orderProvider) {
    _orderProvider.addListener(_updateHistoryFromOrders);
    _updateHistoryFromOrders();
  }

  List<RideHistoryEntry> get filteredHistoryEntries => _filteredHistoryEntries;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  HistoryFilterType get currentFilterType => _currentFilterType;

  void updateOrderProvider(OrderProvider newOrderProvider) {
    if (_orderProvider != newOrderProvider) {
      _orderProvider.removeListener(_updateHistoryFromOrders);
      _orderProvider = newOrderProvider;
      _orderProvider.addListener(_updateHistoryFromOrders);
      _updateHistoryFromOrders();
    }
  }

  void _updateHistoryFromOrders() {
    _allHistoryEntries = _orderProvider.orderHistory.map((order) {
      return RideHistoryEntry(
        id: order.id,
        type: order.type,
        dateTime: order.creationTime,
        origin: order.pickupAddress,
        destination: order.deliveryAddress,
        value: order.estimatedValue,
        status: order.status,
        paymentMethod: order.paymentMethod, // <-- campo adicionado!
        notes: order.notes,
        code: "#${order.id}",
        userName: order.customerName ?? "@usuário",
        timeStart: DateFormat('HH:mm').format(order.creationTime),
        timeAccepted: DateFormat('HH:mm').format(order.creationTime.add(const Duration(minutes: 7))),
        timeDelivered: DateFormat('HH:mm').format(order.creationTime.add(const Duration(minutes: 18))),
      );
    }).toList();

    _applyFilterLogic(_currentFilterType, customRange: _selectedDateRange);
    _sortEntries();
    notifyListeners();
  }

  // ORDENA os pedidos mais recentes EM CIMA (ordem de chegada)
  void _sortEntries() {
    _filteredHistoryEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    // Se quiser ativos em cima e finalizados/cancelados embaixo, use isso:
    /*
    _filteredHistoryEntries.sort((a, b) {
      int statusPriority(A) {
        // Defina status considerados ATIVOS:
        if (A.status == OrderStatus.completed ||
            A.status == OrderStatus.cancelledByCustomer ||
            A.status == OrderStatus.cancelledByDriver ||
            A.status == OrderStatus.cancelledBySystem) return 1;
        return 0;
      }
      int cmp = statusPriority(a).compareTo(statusPriority(b));
      if (cmp != 0) return cmp;
      return b.dateTime.compareTo(a.dateTime);
    });
    */
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
      _selectedDateRange = DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999));
    } else if (filterType == HistoryFilterType.yesterday) {
      final yesterdayStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      _selectedDateRange = DateTimeRange(
          start: yesterdayStart,
          end: DateTime(yesterdayStart.year, yesterdayStart.month, yesterdayStart.day, 23, 59, 59, 999));
    } else if (filterType == HistoryFilterType.customRange && customRange != null) {
      _selectedDateRange = customRange;
    } else {
      _selectedDateRange = null;
    }

    _applyFilterLogic(filterType, customRange: _selectedDateRange);
    _sortEntries();
    notifyListeners();
  }

  @override
  void dispose() {
    _orderProvider.removeListener(_updateHistoryFromOrders);
    super.dispose();
  }
}