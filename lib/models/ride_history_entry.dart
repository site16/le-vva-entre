// lib/models/ride_history_entry.dart
import 'package:flutter/material.dart';
import 'package:levva_entregador/models/order_model.dart'; // Assumindo que OrderType e OrderStatus estão aqui

class RideHistoryEntry {
  final String id;
  final OrderType type; // Usando o enum do seu order_model.dart
  final DateTime dateTime;
  final String origin;
  final String destination;
  final double value;
  final OrderStatus status; // Usando o enum do seu order_model.dart
  final String? notes; // Opcional: para mais detalhes

  RideHistoryEntry({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.origin,
    required this.destination,
    required this.value,
    required this.status,
    this.notes,
  });

  // Helper para obter o ícone baseado no tipo de pedido
  IconData get iconData {
    switch (type) {
      case OrderType.moto:
        return Icons.motorcycle_rounded;
      case OrderType.package:
        return Icons.inventory_2_outlined; // Ícone diferente para pacotes
      case OrderType.food:
        return Icons.fastfood_rounded;
      default:
        return Icons.delivery_dining_rounded;
    }
  }

  // Helper para obter a cor baseada no status
  Color getStatusColor(BuildContext context) {
    if (status.name.toLowerCase().contains('cancel')) {
      return Colors.red.shade600;
    }
    if (status == OrderStatus.completed) {
      return Colors.green.shade600;
    }
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.6); // Cor padrão
  }

  // Helper para obter o nome do tipo de maneira amigável
  String get typeName {
     switch (type) {
      case OrderType.moto:
        return 'Passageiro (Moto)';
      case OrderType.package:
        return 'Entrega de Pacote';
      case OrderType.food:
        return 'Delivery de Comida';
      default:
        return type.name;
    }
  }

  // Helper para obter o nome do status de maneira amigável
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
      default:
        // Pega o nome do enum, remove "OrderStatus." e capitaliza a primeira letra
        String name = status.name;
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}