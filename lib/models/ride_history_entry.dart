import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:levva_entregador/models/order_model.dart';

class RideHistoryEntry {
  final String id;
  final OrderType type;
  final DateTime dateTime;
  final String origin;
  final String destination;
  final double value;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String? code;
  final String? userName;
  final String? timeStart;
  final String? timeAccepted;
  final String? timeDelivered;

  RideHistoryEntry({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.origin,
    required this.destination,
    required this.value,
    required this.status,
    required this.paymentMethod,
    this.notes,
    this.code,
    this.userName,
    this.timeStart,
    this.timeAccepted,
    this.timeDelivered,
  });

  // Firebase: Criação do modelo a partir de um DocumentSnapshot
  factory RideHistoryEntry.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    T _enumFromString<T>(List<T> enumValues, String value, T defaultValue) {
      try {
        return enumValues.firstWhere((e) => (e as Enum).name == value);
      } catch (_) {
        return defaultValue;
      }
    }

    return RideHistoryEntry(
      id: doc.id,
      type: _enumFromString(OrderType.values, data['type'] as String? ?? OrderType.unknown.name, OrderType.unknown),
      dateTime: (data['dateTime'] is Timestamp)
          ? (data['dateTime'] as Timestamp).toDate()
          : (data['dateTime'] is String)
              ? DateTime.tryParse(data['dateTime']) ?? DateTime.now()
              : DateTime.now(),
      origin: data['origin'] ?? '',
      destination: data['destination'] ?? '',
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      status: _enumFromString(OrderStatus.values, data['status'] as String? ?? OrderStatus.unknown.name, OrderStatus.unknown),
      paymentMethod: _enumFromString(PaymentMethod.values, data['paymentMethod'] as String? ?? PaymentMethod.online.name, PaymentMethod.online),
      notes: data['notes'],
      code: data['code'],
      userName: data['userName'],
      timeStart: data['timeStart'],
      timeAccepted: data['timeAccepted'],
      timeDelivered: data['timeDelivered'],
    );
  }

  // Firebase: Serialização para Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'dateTime': dateTime,
      'origin': origin,
      'destination': destination,
      'value': value,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'code': code,
      'userName': userName,
      'timeStart': timeStart,
      'timeAccepted': timeAccepted,
      'timeDelivered': timeDelivered,
    };
  }

  // Ícone para o tipo de pedido
  IconData get iconData {
    switch (type) {
      case OrderType.moto:
        return Icons.motorcycle_rounded;
      case OrderType.package:
        return Icons.inventory_2_outlined;
      case OrderType.food:
        return Icons.fastfood_rounded;
      default:
        return Icons.delivery_dining_rounded;
    }
  }

  // Nome amigável do tipo
  String get typeName {
    switch (type) {
      case OrderType.moto:
        return 'Passageiro (Moto)';
      case OrderType.package:
        return 'Entrega de Pacote';
      case OrderType.food:
        return 'Delivery de Comida';
      default:
        return 'Outro';
    }
  }

  // Texto do status
  String get statusName {
    switch (status) {
      case OrderStatus.completed:
        return 'Concluída';
      case OrderStatus.cancelledByCustomer:
        return 'Cancelada pelo Cliente';
      case OrderStatus.cancelledByDriver:
        return 'Cancelada por Você';
      case OrderStatus.cancelledBySystem:
        return 'Cancelada pelo Sistema';
      case OrderStatus.pendingAcceptance:
        return 'Aguardando aceite';
      case OrderStatus.toPickup:
        return 'A caminho da coleta';
      case OrderStatus.atPickup:
        return 'No local da coleta';
      case OrderStatus.awaitingPickup:
        return 'Aguardando coleta';
      case OrderStatus.toDeliver:
        return 'A caminho da entrega';
      case OrderStatus.atDelivery:
        return 'No local da entrega';
      case OrderStatus.returningToStore:
        return 'Retornando à loja';
      case OrderStatus.awaitingStoreConfirmation:
        return 'Aguardando confirmação da loja';
      case OrderStatus.cancellationRequested:
        return 'Cancelamento solicitado';
      default:
        return 'Indefinido';
    }
  }

  // Cor do status para o texto do status
  Color getStatusColor(BuildContext context) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green.shade700;
      case OrderStatus.cancelledByCustomer:
      case OrderStatus.cancelledByDriver:
      case OrderStatus.cancelledBySystem:
        return Colors.red.shade700;
      case OrderStatus.pendingAcceptance:
        return Colors.orange.shade800;
      case OrderStatus.toPickup:
      case OrderStatus.atPickup:
      case OrderStatus.awaitingPickup:
        return Colors.blue.shade700;
      case OrderStatus.toDeliver:
      case OrderStatus.atDelivery:
        return Colors.indigo.shade700;
      case OrderStatus.returningToStore:
        return Colors.deepPurple.shade700;
      case OrderStatus.awaitingStoreConfirmation:
        return Colors.amber.shade800;
      case OrderStatus.cancellationRequested:
        return Colors.red.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Salva/atualiza entrada do histórico no Firestore
  Future<void> saveToFirestore(String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('ride_history')
        .doc(id);
    await docRef.set(toMap(), SetOptions(merge: true));
  }

  /// Busca todas as rides do usuário
  static Future<List<RideHistoryEntry>> fetchHistory(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('ride_history')
        .orderBy('dateTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => RideHistoryEntry.fromDocument(doc))
        .toList();
  }

  /// Busca uma ride específica pelo id
  static Future<RideHistoryEntry?> fetchById(String userId, String rideId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('ride_history')
        .doc(rideId)
        .get();
    if (doc.exists) {
      return RideHistoryEntry.fromDocument(doc);
    }
    return null;
  }
}