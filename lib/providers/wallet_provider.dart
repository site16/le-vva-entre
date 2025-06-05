// lib/providers/wallet_provider.dart
import 'package:flutter/foundation.dart';
import 'package:levva_entregador/models/wallet_transaction_model.dart';
import 'package:levva_entregador/models/order_model.dart'; // Ajuste o caminho se necessário

class WalletProvider with ChangeNotifier {
  double _onlineBalance = 0.0;
  double _cashBalance = 0.0; // Informativo, valor já coletado pelo entregador
  double _grossEarningsForCommission = 0.0; // Ganhos brutos (online + dinheiro/maquininha) para cálculo da comissão

  List<WalletTransaction> _transactions = [];
  bool _isLoading = false;

  // Taxas da plataforma (campos privados)
  final double _maintenanceFeePercentage = 0.10; // 10%
  final double _transferFeePercentage = 0.015;   // 1.5%

  // Getters públicos para os saldos e estado
  double get onlineBalance => _onlineBalance;
  double get cashBalance => _cashBalance;
  double get grossEarningsForCommission => _grossEarningsForCommission;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  // GETTERS PÚBLICOS PARA AS PORCENTAGENS DAS TAXAS
  double get maintenanceFeePercentage => _maintenanceFeePercentage;
  double get transferFeePercentage => _transferFeePercentage;

  // Getter para a taxa de comissão total
  double get totalCommissionRate => _maintenanceFeePercentage + _transferFeePercentage;

  // Simula a busca de dados (ex: para pull-to-refresh)
  Future<void> fetchWalletData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1)); // Simula atraso de rede

    // Nenhuma transação de exemplo é adicionada aqui.
    // O provider agora depende inteiramente das chamadas de 'addTransactionForOrderCompletion'
    // vindas do OrderProvider para popular os dados.
    // Em um app real, esta função buscaria os dados de um backend ou armazenamento local.
    // Para a simulação atual, manter os dados em memória é suficiente.

    _isLoading = false;
    notifyListeners();
  }

  // Adiciona transação por conclusão de pedido (chamado pelo OrderProvider)
  void addTransactionForOrderCompletion(Order completedOrder) {
    double earnings = completedOrder.estimatedValue;
    if (earnings <= 0) {
      if (kDebugMode) {
        print("WalletProvider: Ganhos zerados ou negativos para o pedido ${completedOrder.id}, nenhuma transação adicionada.");
      }
      return;
    }

    TransactionType transactionType;
    String description;
    String orderIdShort = completedOrder.id.substring(0, _getSafeSubstringLength(completedOrder.id, 6));
    String paymentMethodName = "Desconhecido";

    switch (completedOrder.paymentMethod) {
      case PaymentMethod.online:
      case PaymentMethod.levvaPay: // Tratar LevvaPay como online
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
      case PaymentMethod.card: // Decisão de negócio: tratar como online ou maquininha? Assumindo online por padrão.
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
    if (kDebugMode) {
      print("WalletProvider: Pedido ${completedOrder.id} (Pagamento: ${completedOrder.paymentMethod.name}) finalizado. Ganho de R\$$earnings. Saldo Online: R\$$_onlineBalance, Saldo Dinheiro/Maq.: R\$$_cashBalance, Bruto Comissão: R\$$_grossEarningsForCommission");
    }
    notifyListeners();
  }

  // Calcula detalhes do saque proposto
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

  // Processa a solicitação de saque
  Future<void> requestWithdrawal(double requestedAmountFromOnline) async {
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

    _grossEarningsForCommission = 0.0; // Zera, pois a comissão foi liquidada

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

    _isLoading = false;
    if (kDebugMode) {
      print("WalletProvider: Saque de R\$$totalDebitFromOnline processado. Líquido: R\$$netAmountToReceive. Comissão Retida: R\$$platformCommission. Novo Saldo Online: R\$$_onlineBalance. Novo Bruto Comissão: R\$$_grossEarningsForCommission");
    }
    notifyListeners();
  }

  // Função auxiliar para evitar erros de substring
  int _getSafeSubstringLength(String text, int maxLength) {
    return text.length < maxLength ? text.length : maxLength;
  }
}