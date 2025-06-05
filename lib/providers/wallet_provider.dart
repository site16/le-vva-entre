import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:levva_entregador/models/wallet_transaction_model.dart';
import 'package:levva_entregador/models/order_model.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';

enum WalletFilterType { all, today, yesterday, customRange }

class WalletSnapshot {
  final DateTime referenceDate;
  final double cashBalanceSnapshot;
  final double grossEarningsForCommissionSnapshot;

  WalletSnapshot({
    required this.referenceDate,
    required this.cashBalanceSnapshot,
    required this.grossEarningsForCommissionSnapshot,
  });
}

class WalletProvider with ChangeNotifier {
  double _onlineBalance = 0.0;
  double _cashBalance = 0.0;
  double _grossEarningsForCommission = 0.0;

  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;

  WalletFilterType _currentFilterType = WalletFilterType.all;
  DateTimeRange? _selectedDateRange;
  List<WalletTransaction> _filteredTransactions = [];

  final Map<String, WalletSnapshot> _monthlySnapshots = {};

  WalletFilterType get currentFilterType => _currentFilterType;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  List<WalletTransaction> get filteredTransactions => List.unmodifiable(_filteredTransactions);
  Map<String, WalletSnapshot> get monthlySnapshots => Map.unmodifiable(_monthlySnapshots);

  final double _maintenanceFeePercentage = 0.10; // 10%
  final double _transferFeePercentage = 0.015;   // 1.5%

  double get onlineBalance => _onlineBalance;
  double get cashBalance => _cashBalance;
  double get grossEarningsForCommission => _grossEarningsForCommission;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  double get maintenanceFeePercentage => _maintenanceFeePercentage;
  double get transferFeePercentage => _transferFeePercentage;
  double get totalCommissionRate => _maintenanceFeePercentage + _transferFeePercentage;

  void ensureMonthlySnapshot() {
    final now = DateTime.now();
    final key = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    if (!_monthlySnapshots.containsKey(key)) {
      _monthlySnapshots[key] = WalletSnapshot(
        referenceDate: DateTime(now.year, now.month, 1),
        cashBalanceSnapshot: _cashBalance,
        grossEarningsForCommissionSnapshot: _grossEarningsForCommission,
      );
      _cashBalance = 0.0;
      if (_onlineBalance > 0) {
        _grossEarningsForCommission = _onlineBalance;
      } else {
        _grossEarningsForCommission = 0.0;
      }
      notifyListeners();
    }
  }

  WalletSnapshot? getSnapshotForMonth(int year, int month) {
    final key = "$year-${month.toString().padLeft(2, '0')}";
    return _monthlySnapshots[key];
  }

  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    ensureMonthlySnapshot();
    _applyFilter();
    notifyListeners();
  }

  void addTransactionForOrderCompletion(Order completedOrder) {
    ensureMonthlySnapshot();

    double earnings = completedOrder.estimatedValue;
    if (earnings <= 0) {
      return;
    }

    TransactionType transactionType;
    String description;
    String orderIdShort = completedOrder.id.substring(0, completedOrder.id.length < 6 ? completedOrder.id.length : 6);
    String paymentMethodName = "Desconhecido";

    switch (completedOrder.paymentMethod) {
      case PaymentMethod.online:
      case PaymentMethod.levvaPay:
        _onlineBalance += earnings;
        transactionType = TransactionType.creditOnlineEarning;
        paymentMethodName = "Online";
        break;
      case PaymentMethod.cash:
        _cashBalance += earnings;
        transactionType = TransactionType.infoCashEarning;
        paymentMethodName = "Dinheiro";
        break;
      case PaymentMethod.cardMachine:
        _cashBalance += earnings;
        transactionType = TransactionType.infoCashEarning;
        paymentMethodName = "Maquininha";
        break;
      case PaymentMethod.card:
        _onlineBalance += earnings;
        transactionType = TransactionType.creditOnlineEarning;
        paymentMethodName = "Cartão (Online)";
        break;
    }
    description = 'Ganho $paymentMethodName - Pedido #$orderIdShort';

    _grossEarningsForCommission += earnings;

    final newTransaction = WalletTransaction(
      id: 'ORDER_${transactionType.name}_${completedOrder.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: transactionType,
      description: description,
      amount: earnings,
      date: DateTime.now(),
      orderId: completedOrder.id,
    );

    _transactions.insert(0, newTransaction);
    _applyFilter();
    notifyListeners();
  }

  Map<String, double> calculateWithdrawalDetails(double requestedAmountFromOnline) {
    if (requestedAmountFromOnline <= 0) {
      return {
        'requestedAmount': 0.0,
        'platformCommission': 0.0,
        'netAmountToReceive': 0.0,
        'totalDebitFromOnline': 0.0
      };
    }

    double platformCommission = _grossEarningsForCommission * totalCommissionRate;
    platformCommission = (platformCommission * 100).roundToDouble() / 100;

    double netAmountToReceive = requestedAmountFromOnline - platformCommission;
    netAmountToReceive = (netAmountToReceive * 100).roundToDouble() / 100;

    return {
      'requestedAmount': requestedAmountFromOnline,
      'platformCommission': platformCommission,
      'netAmountToReceive': netAmountToReceive,
      'totalDebitFromOnline': requestedAmountFromOnline,
    };
  }

  Future<void> requestWithdrawal(double requestedAmountFromOnline, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    final details = calculateWithdrawalDetails(requestedAmountFromOnline);
    final platformCommission = details['platformCommission']!;
    final netAmountToReceive = details['netAmountToReceive']!;
    final totalDebitFromOnline = details['totalDebitFromOnline']!;

    if (totalDebitFromOnline <= 0) {
      _isLoading = false;
      notifyListeners();
      throw Exception('O valor do saque deve ser positivo.');
    }
    if (totalDebitFromOnline > _onlineBalance) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Saldo LevvaPay (R\$${_onlineBalance.toStringAsFixed(2)}) insuficiente para sacar R\$${totalDebitFromOnline.toStringAsFixed(2)}.');
    }
    if (netAmountToReceive <= 0) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Saque de R\$${totalDebitFromOnline.toStringAsFixed(2)} não cobre a comissão da plataforma (R\$${platformCommission.toStringAsFixed(2)}). Líquido seria R\$${netAmountToReceive.toStringAsFixed(2)}.');
    }

    _onlineBalance -= totalDebitFromOnline;
    _onlineBalance = (_onlineBalance * 100).roundToDouble() / 100;

    _grossEarningsForCommission = 0.0;

    _transactions.insert(
        0,
        WalletTransaction(
          id: 'WDRW_${DateTime.now().millisecondsSinceEpoch}',
          type: TransactionType.debitWithdrawalFromOnline,
          description:
              'Saque Solicitado. Líquido: R\$${netAmountToReceive.toStringAsFixed(2)} (Comissão Retida: R\$${platformCommission.toStringAsFixed(2)})',
          amount: -totalDebitFromOnline,
          date: DateTime.now(),
        ));

    // Notificação de saque
    Provider.of<NotificationProvider>(context, listen: false).addWithdrawalNotification(
      requested: totalDebitFromOnline,
      net: netAmountToReceive,
      fees: platformCommission,
      status: "Pendente",
    );

    _applyFilter();
    _isLoading = false;
    notifyListeners();
  }

  void applyFilter(WalletFilterType filterType, {DateTimeRange? customRange}) {
    _currentFilterType = filterType;
    if (filterType == WalletFilterType.customRange && customRange != null) {
      _selectedDateRange = customRange;
    } else {
      _selectedDateRange = null;
    }
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = todayEnd.subtract(const Duration(days: 1));

    switch (_currentFilterType) {
      case WalletFilterType.all:
        _filteredTransactions = List.from(_transactions);
        break;
      case WalletFilterType.today:
        _filteredTransactions = _transactions.where((tx) =>
          !tx.date.isBefore(todayStart) && !tx.date.isAfter(todayEnd)
        ).toList();
        break;
      case WalletFilterType.yesterday:
        _filteredTransactions = _transactions.where((tx) =>
          !tx.date.isBefore(yesterdayStart) && !tx.date.isAfter(yesterdayEnd)
        ).toList();
        break;
      case WalletFilterType.customRange:
        if (_selectedDateRange != null) {
          final rangeStart = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
          final rangeEnd = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59, 999);
          _filteredTransactions = _transactions.where((tx) =>
            !tx.date.isBefore(rangeStart) && !tx.date.isAfter(rangeEnd)
          ).toList();
        } else {
          _filteredTransactions = List.from(_transactions);
        }
        break;
    }
    _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
  }
}