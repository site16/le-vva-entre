// lib/models/wallet_transaction_model.dart

enum TransactionType {
  // Créditos / Entradas
  creditOnlineEarning,      // Ganho de pedido com pagamento online (entra no saldo online e bruto)
  infoCashEarning,          // Ganho bruto informativo de pedido em dinheiro/maquininha (entra no saldo cash e bruto)
  creditManualAdjustment,   // Crédito manual (bônus, ajustes positivos) - definir como afeta saldos
  // deposit,               // Se o entregador puder depositar na plataforma

  // Débitos / Saídas
  debitWithdrawalFromOnline,// Saque do saldo online (debita do online, "quita" comissão sobre o bruto acumulado)
  // debitServiceFee,       // Taxa de serviço avulsa (se houver, fora da comissão principal)
  debitManualAdjustment,    // Débito manual (ajustes negativos)

  // Manter apenas os tipos que você realmente usa.
  // Os tipos abaixo são do seu código original, avalie se ainda são necessários
  // ou se foram substituídos/englobados pelos acima.
  credit, debit, // Muito genéricos, prefira os específicos
  /*
  creditOnlineOrderEarning, // Substituído por creditOnlineEarning
  debitWithdrawal, // Substituído por debitWithdrawalFromOnline
  creditGrossCashEarning, // Substituído por infoCashEarning
  creditGrossOnlineEarning, // Substituído por creditOnlineEarning
  debitWithdrawalFee, // Agora parte da comissão retida no debitWithdrawalFromOnline
  maintenanceFee, // Idem
  */
}

class WalletTransaction {
  final String id;
  final TransactionType type;
  final String description;
  final double amount; // Positivo para créditos, negativo para débitos
  final DateTime date;
  final String? orderId;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    this.orderId,
  });

  // Seus métodos fromMap e toMap parecem bons.
  // Adapte o orElse no fromMap para um fallback que faça sentido para seus dados.
  factory WalletTransaction.fromMap(Map<String, dynamic> data, String documentId) {
    return WalletTransaction(
      id: documentId,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.creditManualAdjustment // Exemplo de fallback seguro
      ),
      description: data['description'] ?? 'Transação sem descrição',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] != null ? DateTime.parse(data['date'] as String) : DateTime.now(),
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'orderId': orderId,
    };
  }
}