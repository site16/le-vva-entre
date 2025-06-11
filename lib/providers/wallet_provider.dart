import 'package:flutter/material.dart';
import '../models/wallet_transaction_model.dart';

enum WalletFilterType { all, today, yesterday, customRange }

class WalletProvider extends ChangeNotifier {
  double _onlineBalance = 0.0;
  double _cashBalance = 0.0;
  double _grossEarningsForCommission = 0.0;
  bool _isLoading = false;

  WalletFilterType _currentFilterType = WalletFilterType.all;
  DateTimeRange? _selectedDateRange;
  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> _filteredTransactions = [];

  // Taxas simuladas
  final double maintenanceFeePercentage = 0.08;
  final double transferFeePercentage = 0.03;

  WalletProvider() {
    fetchWalletData();
  }

  // Getters
  double get onlineBalance => _onlineBalance;
  double get cashBalance => _cashBalance;
  double get grossEarningsForCommission => _grossEarningsForCommission;
  double get totalCommissionRate => maintenanceFeePercentage + transferFeePercentage;
  bool get isLoading => _isLoading;
  WalletFilterType get currentFilterType => _currentFilterType;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  List<WalletTransaction> get filteredTransactions => List.unmodifiable(_filteredTransactions);

  /// Busca dados simulados. Troque pela lógica real com Firestore se desejar.
  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();

    // Exemplo de dados simulados. Substitua por fetch do Firestore.
    await Future.delayed(const Duration(milliseconds: 800));
    _transactions = [
      WalletTransaction(
        id: UniqueKey().toString(),
        amount: 100.0,
        date: DateTime.now().subtract(const Duration(hours: 1)),
        description: 'Corrida concluída',
        type: TransactionType.creditOnlineEarning,
      ),
      WalletTransaction(
        id: UniqueKey().toString(),
        amount: -50.0,
        date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        description: 'Saque realizado',
        type: TransactionType.debitWithdrawalFromOnline,
      ),
      WalletTransaction(
        id: UniqueKey().toString(),
        amount: 30.0,
        date: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
        description: 'Corrida concluída',
        type: TransactionType.creditOnlineEarning,
      ),
      WalletTransaction(
        id: UniqueKey().toString(),
        amount: 40.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Recebido em dinheiro',
        type: TransactionType.infoCashEarning,
      ),
    ];

    // Simulando valores
    _onlineBalance = _transactions
        .where((t) => t.type == TransactionType.creditOnlineEarning)
        .fold(0.0, (sum, t) => sum + t.amount)
      - _transactions
          .where((t) => t.type == TransactionType.debitWithdrawalFromOnline)
          .fold(0.0, (sum, t) => sum + t.amount.abs());

    _cashBalance = _transactions
        .where((t) => t.type == TransactionType.infoCashEarning)
        .fold(0.0, (sum, t) => sum + t.amount);

    _grossEarningsForCommission = _transactions
        .where((t) => t.type == TransactionType.creditOnlineEarning)
        .fold(0.0, (sum, t) => sum + t.amount);

    _applyFilterInternal(_currentFilterType, customRange: _selectedDateRange);

    _isLoading = false;
    notifyListeners();
  }

  void applyFilter(WalletFilterType filterType, {DateTimeRange? customRange}) {
    _currentFilterType = filterType;
    _selectedDateRange = (filterType == WalletFilterType.customRange) ? customRange : null;
    _applyFilterInternal(filterType, customRange: customRange);
    notifyListeners();
  }

  void _applyFilterInternal(WalletFilterType filterType, {DateTimeRange? customRange}) {
    DateTime now = DateTime.now();
    _filteredTransactions = switch (filterType) {
      WalletFilterType.all => List.from(_transactions),
      WalletFilterType.today => _transactions.where((tx) {
        return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
      }).toList(),
      WalletFilterType.yesterday => _transactions.where((tx) {
        final yesterday = now.subtract(const Duration(days: 1));
        return tx.date.year == yesterday.year && tx.date.month == yesterday.month && tx.date.day == yesterday.day;
      }).toList(),
      WalletFilterType.customRange when customRange != null => _transactions.where((tx) {
        return tx.date.isAfter(customRange.start.subtract(const Duration(seconds: 1)))
            && tx.date.isBefore(customRange.end.add(const Duration(days: 1)));
      }).toList(),
      _ => List.from(_transactions),
    };
    _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
  }

  /// Calcula taxas e o valor líquido para saque.
  Map<String, double> calculateWithdrawalDetails(double requestedAmount) {
    double commission = requestedAmount * totalCommissionRate;
    double netAmount = requestedAmount - commission;
    return {
      'requestedAmount': requestedAmount,
      'maintenanceFee': requestedAmount * maintenanceFeePercentage,
      'transferFee': requestedAmount * transferFeePercentage,
      'totalCommission': commission,
      'netAmountToReceive': netAmount > 0 ? netAmount : 0.0,
      'totalDebitFromOnline': requestedAmount, // pode somar taxas se for sua regra
    };
  }

  /// Solicita saque (aqui apenas simulado)
  Future<void> requestWithdrawal(double amount, BuildContext context) async {
    if (amount <= 0) throw Exception('Valor inválido.');
    final details = calculateWithdrawalDetails(amount);
    if ((details['totalDebitFromOnline'] ?? 0) > onlineBalance) {
      throw Exception('Saldo insuficiente.');
    }
    // Simula saque
    _transactions.insert(
      0,
      WalletTransaction(
        id: UniqueKey().toString(),
        amount: -amount,
        date: DateTime.now(),
        description: 'Saque realizado',
        type: TransactionType.debitWithdrawalFromOnline,
      ),
    );
    _onlineBalance -= amount;
    applyFilter(_currentFilterType, customRange: _selectedDateRange);
    notifyListeners();
  }

  /// Adiciona uma transação relacionada à conclusão de um pedido.
  Future<void> addTransactionForOrderCompletion({
    required String orderId,
    required double amount,
    required DateTime date,
    required bool paidOnline,
  }) async {
    final TransactionType txType = paidOnline
        ? TransactionType.creditOnlineEarning
        : TransactionType.infoCashEarning;

    final tx = WalletTransaction(
      id: UniqueKey().toString(),
      type: txType,
      description: paidOnline ? 'Recebimento online do pedido' : 'Recebimento em dinheiro do pedido',
      amount: amount,
      date: date,
      orderId: orderId,
    );
    _transactions.insert(0, tx);
    if (paidOnline) {
      _onlineBalance += amount;
      _grossEarningsForCommission += amount;
    } else {
      _cashBalance += amount;
      _grossEarningsForCommission += amount;
    }
    applyFilter(_currentFilterType, customRange: _selectedDateRange);
    notifyListeners();
  }
}