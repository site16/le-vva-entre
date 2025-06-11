import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_type_enum.dart';

enum PaymentMethod { online, cash, cardMachine, levvaPay, card }
enum OrderType { moto, package, food, unknown }
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
  unknown,
  started,
  accepted,
  delivered,
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
  final String? notes;
  final String? driverId;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;

  // Campo para o código de confirmação (os 4 últimos dígitos ou código do backend)
  final String? confirmationCode;

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
    this.waitingSince,
    this.notes,
    this.driverId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.confirmationCode, // <-- Usar este campo
  });

  /// Getter retrocompatível a partir do número de telefone (apenas para fallback!)
  String? get fallbackConfirmationCode {
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'estimatedValue': estimatedValue,
        'distanceToPickup': distanceToPickup,
        'routeDistance': routeDistance,
        'status': status.name,
        'creationTime': creationTime,
        'customerName': customerName,
        'storeName': storeName,
        'items': items,
        'suitableVehicleTypes': suitableVehicleTypes.map((v) => v.name).toList(),
        'paymentMethod': paymentMethod.name,
        'recipientPhoneNumber': recipientPhoneNumber,
        'waitingSince': waitingSince,
        'notes': notes,
        'driverId': driverId,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'deliveryLatitude': deliveryLatitude,
        'deliveryLongitude': deliveryLongitude,
        'confirmationCode': confirmationCode, // <-- Sempre serialize como confirmationCode
      };

  factory Order.fromDocument(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    T enumFromString<T>(List<T> enumValues, String value, T defaultValue) {
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
      id: doc.id,
      type: enumFromString(OrderType.values, json['type'] as String? ?? OrderType.unknown.name, OrderType.unknown),
      pickupAddress: json['pickupAddress'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0.0,
      distanceToPickup: (json['distanceToPickup'] as num?)?.toDouble() ?? 0.0,
      routeDistance: (json['routeDistance'] as num?)?.toDouble() ?? 0.0,
      status: enumFromString(OrderStatus.values, json['status'] as String? ?? OrderStatus.unknown.name, OrderStatus.unknown),
      creationTime: (json['creationTime'] is Timestamp)
          ? (json['creationTime'] as Timestamp).toDate()
          : (json['creationTime'] is String)
              ? DateTime.parse(json['creationTime'])
              : DateTime.now(),
      customerName: json['customerName'] as String?,
      storeName: json['storeName'] as String?,
      items: (json['items'] as List<dynamic>?)?.map((item) => item as String).toList(),
      suitableVehicleTypes: (json['suitableVehicleTypes'] as List<dynamic>?)
              ?.map((v) => enumFromString(VehicleType.values, v as String? ?? VehicleType.unknown.name, VehicleType.unknown))
              .where((v) => v != VehicleType.unknown)
              .toList() ??
          const [VehicleType.moto, VehicleType.bike],
      paymentMethod: enumFromString(PaymentMethod.values, json['paymentMethod'] as String? ?? PaymentMethod.online.name, PaymentMethod.online),
      recipientPhoneNumber: json['recipientPhoneNumber'] as String?,
      waitingSince: (json['waitingSince'] is Timestamp)
          ? (json['waitingSince'] as Timestamp).toDate()
          : (json['waitingSince'] is String)
              ? DateTime.tryParse(json['waitingSince'])
              : null,
      notes: json['notes'] as String?,
      driverId: json['driverId'] as String?,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      confirmationCode: json['confirmationCode'] as String? ?? json['deliveryCode'] as String?, // <-- busca ambos para retrocompatibilidade
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    T enumFromString<T>(List<T> enumValues, String value, T defaultValue) {
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
      type: enumFromString(OrderType.values, json['type'] as String? ?? OrderType.unknown.name, OrderType.unknown),
      pickupAddress: json['pickupAddress'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0.0,
      distanceToPickup: (json['distanceToPickup'] as num?)?.toDouble() ?? 0.0,
      routeDistance: (json['routeDistance'] as num?)?.toDouble() ?? 0.0,
      status: enumFromString(OrderStatus.values, json['status'] as String? ?? OrderStatus.unknown.name, OrderStatus.unknown),
      creationTime: json['creationTime'] != null ? DateTime.parse(json['creationTime'] as String) : DateTime.now(),
      customerName: json['customerName'] as String?,
      storeName: json['storeName'] as String?,
      items: (json['items'] as List<dynamic>?)?.map((item) => item as String).toList(),
      suitableVehicleTypes: (json['suitableVehicleTypes'] as List<dynamic>?)
              ?.map((v) => enumFromString(VehicleType.values, v as String? ?? VehicleType.unknown.name, VehicleType.unknown))
              .where((v) => v != VehicleType.unknown)
              .toList() ??
          const [VehicleType.moto, VehicleType.bike],
      paymentMethod: enumFromString(PaymentMethod.values, json['paymentMethod'] as String? ?? PaymentMethod.online.name, PaymentMethod.online),
      recipientPhoneNumber: json['recipientPhoneNumber'] as String?,
      waitingSince: json['waitingSince'] != null ? DateTime.parse(json['waitingSince'] as String) : null,
      notes: json['notes'] as String?,
      driverId: json['driverId'] as String?,
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble(),
      confirmationCode: json['confirmationCode'] as String? ?? json['deliveryCode'] as String?, // <-- busca ambos para retrocompatibilidade
    );
  }
}