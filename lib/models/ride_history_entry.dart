import 'package:flutter/material.dart';
import 'package:levva_entregador/models/order_model.dart';

class RideHistoryEntry {
  final String id;
  final OrderType type;
  final DateTime dateTime;
  final String origin;
  final String destination;
  final double value;
  final OrderStatus status;
  final PaymentMethod paymentMethod; // <-- Adicionado aqui
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
    required this.paymentMethod, // <-- Adicionado aqui
    this.notes,
    this.code,
    this.userName,
    this.timeStart,
    this.timeAccepted,
    this.timeDelivered,
  });

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
}