// lib/models/driver_model.dart
import 'package:flutter/foundation.dart';
import 'vehicle_type_enum.dart';
import 'order_model.dart'; // Para importar OrderType e PaymentMethod

class Driver {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final VehicleType vehicleType;
  final String? vehicleModel;
  final String? licensePlate;
  final String? profileImageUrl;
  final double rating;
  List<OrderType> preferredServiceTypes;
  List<PaymentMethod> preferredPaymentMethods; // Campo adicionado

  Driver({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.vehicleType = VehicleType.moto,
    this.vehicleModel,
    this.licensePlate,
    this.profileImageUrl,
    this.rating = 5.0,
    List<OrderType>? preferredServiceTypes,
    List<PaymentMethod>? preferredPaymentMethods, // Parâmetro adicionado
  }) : preferredServiceTypes =
           preferredServiceTypes ??
           [OrderType.food, OrderType.package, OrderType.moto],
       preferredPaymentMethods =
           preferredPaymentMethods ??
           [
             PaymentMethod.online,
             PaymentMethod.cash,
             PaymentMethod.cardMachine,
           ]; // Inicialização adicionada

  factory Driver.fromMap(Map<String, dynamic> data, String documentId) {
    List<PaymentMethod> parsedPaymentMethods = [];
    if (data['preferredPaymentMethods'] != null &&
        data['preferredPaymentMethods'] is List) {
      parsedPaymentMethods =
          (data['preferredPaymentMethods'] as List<dynamic>)
              .map((methodStr) {
                try {
                  return PaymentMethod.values.firstWhere(
                    (e) => e.name == methodStr.toString(),
                  );
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      'Valor de PaymentMethod inválido "$methodStr" encontrado para o driver $documentId. Será ignorado.',
                    );
                  }
                  return null;
                }
              })
              .where((method) => method != null)
              .toList()
              .cast<PaymentMethod>();
    }

    return Driver(
      id: documentId,
      name: data['name'] ?? 'Nome Indisponível',
      email: data['email'] ?? 'email@indisponivel.com',
      phone: data['phone'],
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == data['vehicleType'],
        orElse: () => VehicleType.unknown,
      ),
      vehicleModel: data['vehicleModel'],
      licensePlate: data['licensePlate'],
      profileImageUrl: data['profileImageUrl'],
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      preferredServiceTypes:
          (data['preferredServiceTypes'] as List<dynamic>?)
              ?.map(
                (typeStr) => OrderType.values.firstWhere(
                  (e) => e.name == typeStr,
                  orElse: () => OrderType.unknown,
                ),
              )
              .where((type) => type != OrderType.unknown)
              .toList() ??
          [OrderType.food, OrderType.package, OrderType.moto],
      preferredPaymentMethods:
          parsedPaymentMethods.isNotEmpty
              ? parsedPaymentMethods
              : [
                PaymentMethod.online,
                PaymentMethod.cash,
                PaymentMethod.cardMachine,
              ], // Lógica de desserialização e fallback
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType.name,
      'vehicleModel': vehicleModel,
      'licensePlate': licensePlate,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'preferredServiceTypes':
          preferredServiceTypes.map((type) => type.name).toList(),
      'preferredPaymentMethods':
          preferredPaymentMethods
              .map((method) => method.name)
              .toList(), // Serialização adicionada
    };
  }
}
