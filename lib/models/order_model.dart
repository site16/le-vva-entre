import 'package:flutter/foundation.dart'; // Para kDebugMode, se usar nos fromJson
import 'package:levva_entregador/models/vehicle_type_enum.dart';

/// Enum para os métodos de pagamento.
enum PaymentMethod { online, cash, cardMachine, levvaPay, card }

/// Enum para os tipos de pedido.
enum OrderType { moto, package, food, unknown }

/// Enum para todos os status possíveis de um pedido.
enum OrderStatus {
  pendingAcceptance,
  toPickup,
  atPickup,
  awaitingPickup,
  toDeliver,
  atDelivery,
  returningToStore,
  awaitingStoreConfirmation,
  completed,
  cancelledByCustomer,
  cancelledByDriver,
  cancelledBySystem,
  cancellationRequested,
  unknown
}

class Order {
  final String id;
  final OrderType type;
  final String pickupAddress;
  final String deliveryAddress;
  final double estimatedValue;
  final double distanceToPickup;
  final double routeDistance;
  OrderStatus status;
  final DateTime creationTime;
  final String? customerName;
  final String? storeName;
  final List<String>? items;
  final List<VehicleType> suitableVehicleTypes;
  final PaymentMethod paymentMethod;
  final String? recipientPhoneNumber;
  DateTime? waitingSince;

  Order({
    required this.id,
    required this.type,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.estimatedValue,
    required this.distanceToPickup,
    required this.routeDistance,
    this.status = OrderStatus.pendingAcceptance,
    required this.creationTime,
    this.customerName,
    this.storeName,
    this.items,
    this.suitableVehicleTypes = const [VehicleType.moto, VehicleType.bike],
    this.paymentMethod = PaymentMethod.online,
    this.recipientPhoneNumber,
    this.waitingSince, String? confirmationCode,
  });

  String? get confirmationCode {
    if (recipientPhoneNumber != null && recipientPhoneNumber!.length >= 4) {
      return recipientPhoneNumber!.substring(recipientPhoneNumber!.length - 4);
    }
    return null;
  }

  double get currentDistance {
    if (status == OrderStatus.returningToStore) return distanceToPickup;
    bool isPickupPhase = status == OrderStatus.toPickup ||
        status == OrderStatus.atPickup ||
        status == OrderStatus.awaitingPickup;
    return isPickupPhase ? distanceToPickup : routeDistance;
  }

  int get estimatedMinutes {
    return (currentDistance * 2.5).round();
  }

  DateTime get estimatedArrivalTime {
    return DateTime.now().add(Duration(minutes: estimatedMinutes));
  }

  // --- INÍCIO DA SERIALIZAÇÃO E DESSERIALIZAÇÃO ---
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name, // Salva o nome do enum
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'estimatedValue': estimatedValue,
        'distanceToPickup': distanceToPickup,
        'routeDistance': routeDistance,
        'status': status.name, // Salva o nome do enum
        'creationTime': creationTime.toIso8601String(), // Salva DateTime como String ISO8601
        'customerName': customerName,
        'storeName': storeName,
        'items': items, // Lista de strings já é serializável
        'suitableVehicleTypes': suitableVehicleTypes.map((v) => v.name).toList(), // Lista de enums para lista de strings
        'paymentMethod': paymentMethod.name, // Salva o nome do enum
        'recipientPhoneNumber': recipientPhoneNumber,
        'waitingSince': waitingSince?.toIso8601String(), // Salva DateTime opcional como String ISO8601
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    // Helper para converter string de volta para enum com segurança
    T _enumFromString<T>(List<T> enumValues, String value, T defaultValue) {
      try {
        return enumValues.firstWhere((e) => (e as Enum).name == value);
      } catch (e) {
        if (kDebugMode) {
          print('Valor de enum desconhecido "$value" para $T. Usando default: $defaultValue.');
        }
        return defaultValue;
      }
    }

    return Order(
      id: json['id'] as String,
      type: _enumFromString(OrderType.values, json['type'] as String? ?? OrderType.unknown.name, OrderType.unknown),
      pickupAddress: json['pickupAddress'] as String? ?? '', // Fallback para string vazia se nulo
      deliveryAddress: json['deliveryAddress'] as String? ?? '', // Fallback para string vazia se nulo
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0.0,
      distanceToPickup: (json['distanceToPickup'] as num?)?.toDouble() ?? 0.0,
      routeDistance: (json['routeDistance'] as num?)?.toDouble() ?? 0.0,
      status: _enumFromString(OrderStatus.values, json['status'] as String? ?? OrderStatus.unknown.name, OrderStatus.unknown),
      creationTime: json['creationTime'] != null ? DateTime.parse(json['creationTime'] as String) : DateTime.now(), // Fallback para data atual se nulo
      customerName: json['customerName'] as String?,
      storeName: json['storeName'] as String?,
      items: (json['items'] as List<dynamic>?)?.map((item) => item as String).toList(),
      suitableVehicleTypes: (json['suitableVehicleTypes'] as List<dynamic>?)
          ?.map((v) => _enumFromString(VehicleType.values, v as String? ?? VehicleType.unknown.name, VehicleType.unknown))
          .where((v) => v != VehicleType.unknown) // Remove desconhecidos se houver erro na conversão
          .toList() ?? const [VehicleType.moto, VehicleType.bike], // Default se nulo ou vazio no JSON
      paymentMethod: _enumFromString(PaymentMethod.values, json['paymentMethod'] as String? ?? PaymentMethod.online.name, PaymentMethod.online),
      recipientPhoneNumber: json['recipientPhoneNumber'] as String?,
      waitingSince: json['waitingSince'] != null ? DateTime.parse(json['waitingSince'] as String) : null,
    );
  }
  // --- FIM DA SERIALIZAÇÃO E DESSERIALIZAÇÃO ---
}