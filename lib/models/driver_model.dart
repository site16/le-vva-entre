import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<PaymentMethod> preferredPaymentMethods;

  // CAMPOS ADICIONADOS PARA PERFIL COMPLETO
  final String? cpf;
  final String? birthDate;
  final String? cnhImageUrl;        // Foto da CNH (motoboy)
  final String? docImageUrl;        // Documento pessoal (biker)
  final String? cnhOpcionalImageUrl; // CNH opcional (biker)
  final String? vehiclePhotoUrl;    // Foto da moto (motoboy)
  final String? vehicleColor;       // Cor da moto (motoboy)
  final String? renavam;            // Renavam da moto (motoboy)

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
    List<PaymentMethod>? preferredPaymentMethods,
    // CAMPOS NOVOS
    this.cpf,
    this.birthDate,
    this.cnhImageUrl,
    this.docImageUrl,
    this.cnhOpcionalImageUrl,
    this.vehiclePhotoUrl,
    this.vehicleColor,
    this.renavam,
  }) : preferredServiceTypes =
           preferredServiceTypes ??
           [OrderType.food, OrderType.package, OrderType.moto],
       preferredPaymentMethods =
           preferredPaymentMethods ??
           [
             PaymentMethod.online,
             PaymentMethod.cash,
             PaymentMethod.cardMachine,
           ];

  /// Getter resumido para detalhes do veículo para exibir no app do usuário
  String get vehicleDetails {
    // Exemplo: "Moto Honda CG 160, cor preta, placa XYZ-1234"
    List<String> parts = [];
    if (vehicleType != VehicleType.unknown) parts.add(_vehicleTypeToString(vehicleType));
    if (vehicleModel != null && vehicleModel!.isNotEmpty) parts.add(vehicleModel!);
    if (vehicleColor != null && vehicleColor!.isNotEmpty) parts.add('cor $vehicleColor');
    if (licensePlate != null && licensePlate!.isNotEmpty) parts.add('placa $licensePlate');
    return parts.join(', ');
  }

  static String _vehicleTypeToString(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return 'Bicicleta';
      case VehicleType.moto:
        return 'Moto';
      case VehicleType.car:
        return 'Carro';  
      case VehicleType.unknown:
        return 'Veículo';
    }
  }

  /// Criação do modelo a partir de um DocumentSnapshot do Firestore
  factory Driver.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
                      'Valor de PaymentMethod inválido "$methodStr" encontrado para o driver ${doc.id}. Será ignorado.',
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
      id: doc.id,
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
              ],
      // CAMPOS NOVOS (com fallback para null se não existir)
      cpf: data['cpf'],
      birthDate: data['birthDate'],
      cnhImageUrl: data['cnhImageUrl'],
      docImageUrl: data['docImageUrl'],
      cnhOpcionalImageUrl: data['cnhOpcionalImageUrl'],
      vehiclePhotoUrl: data['vehiclePhotoUrl'],
      vehicleColor: data['vehicleColor'],
      renavam: data['renavam'],
    );
  }

  /// Criação do modelo a partir de um Map (útil para JSON ou outros usos)
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
              ],
      // CAMPOS NOVOS (com fallback para null se não existir)
      cpf: data['cpf'],
      birthDate: data['birthDate'],
      cnhImageUrl: data['cnhImageUrl'],
      docImageUrl: data['docImageUrl'],
      cnhOpcionalImageUrl: data['cnhOpcionalImageUrl'],
      vehiclePhotoUrl: data['vehiclePhotoUrl'],
      vehicleColor: data['vehicleColor'],
      renavam: data['renavam'],
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
          preferredPaymentMethods.map((method) => method.name).toList(),
      // NOVOS CAMPOS
      'cpf': cpf,
      'birthDate': birthDate,
      'cnhImageUrl': cnhImageUrl,
      'docImageUrl': docImageUrl,
      'cnhOpcionalImageUrl': cnhOpcionalImageUrl,
      'vehiclePhotoUrl': vehiclePhotoUrl,
      'vehicleColor': vehicleColor,
      'renavam': renavam,
    };
  }

  /// Salva o motorista no Firestore (cria ou atualiza)
  Future<void> saveToFirestore() async {
    final docRef = FirebaseFirestore.instance.collection('drivers').doc(id);
    await docRef.set(toMap(), SetOptions(merge: true));
  }

  /// Busca um motorista do Firestore pelo id
  static Future<Driver?> fetchFromFirestore(String driverId) async {
    final doc =
        await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
    if (doc.exists) {
      return Driver.fromDocument(doc);
    }
    return null;
  }

  /// Atualiza campos do motorista no Firestore
  Future<void> updateFields(Map<String, dynamic> data) async {
    final docRef = FirebaseFirestore.instance.collection('drivers').doc(id);
    await docRef.update(data);
  }
}