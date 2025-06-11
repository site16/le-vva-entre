import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  // Créditos / Entradas
  creditOnlineEarning,      // Ganho de pedido com pagamento online (entra no saldo online e bruto)
  infoCashEarning,          // Ganho bruto informativo de pedido em dinheiro/maquininha (entra no saldo cash e bruto)
  creditManualAdjustment,   // Crédito manual (bônus, ajustes positivos) - definir como afeta saldos

  // Débitos / Saídas
  debitWithdrawalFromOnline,// Saque do saldo online (debita do online, "quita" comissão sobre o bruto acumulado)
  debitManualAdjustment,    // Débito manual (ajustes negativos)

  // Genéricos (evite, prefira os tipos acima)
  credit, 
  debit,
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

  /// Cria uma transação a partir de um documento do Firestore
  factory WalletTransaction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.creditManualAdjustment,
      ),
      description: data['description'] ?? 'Transação sem descrição',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : (data['date'] is String
              ? DateTime.tryParse(data['date']) ?? DateTime.now()
              : DateTime.now()),
      orderId: data['orderId'],
    );
  }

  /// Cria uma transação a partir de um Map (útil para conversões JSON)
  factory WalletTransaction.fromMap(Map<String, dynamic> data, String documentId) {
    return WalletTransaction(
      id: documentId,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.creditManualAdjustment,
      ),
      description: data['description'] ?? 'Transação sem descrição',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : (data['date'] is String
              ? DateTime.tryParse(data['date']) ?? DateTime.now()
              : DateTime.now()),
      orderId: data['orderId'],
    );
  }

  /// Serializa para Firestore/JSON
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'description': description,
      'amount': amount,
      'date': date,
      'orderId': orderId,
    };
  }

  /// Salva/atualiza esta transação na subcoleção do usuário
  Future<void> saveToFirestore(String userId) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .doc(id);
    await ref.set(toMap(), SetOptions(merge: true));
  }

  /// Busca todas as transações da carteira do usuário
  static Future<List<WalletTransaction>> fetchAll(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => WalletTransaction.fromDocument(doc))
        .toList();
  }

  /// Busca uma transação específica
  static Future<WalletTransaction?> fetchById(String userId, String transactionId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wallet_transactions')
        .doc(transactionId)
        .get();
    if (doc.exists) {
      return WalletTransaction.fromDocument(doc);
    }
    return null;
  }
}