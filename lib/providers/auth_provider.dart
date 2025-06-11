import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:levva_entregador/models/order_model.dart';
import '../models/driver_model.dart';

class AuthProvider with ChangeNotifier {
  Driver? _currentDriver;
  bool _isLoading = false;

  Driver? get currentDriver => _currentDriver;
  bool get isAuthenticated => _currentDriver != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initAutoLogin();
  }

  Future<void> _initAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          _currentDriver = Driver.fromDocument(doc);
        } else {
          // Usuário autenticado mas não cadastrado como driver
          await FirebaseAuth.instance.signOut();
          _currentDriver = null;
        }
      } else {
        _currentDriver = null;
      }
    } catch (e) {
      _currentDriver = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Login com e-mail e senha via Firebase Auth.
  /// Após login, busca o perfil do motorista no Firestore pelo uid.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Autentica no Firebase Auth
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;

      // 2. Busca perfil do motorista no Firestore
      final doc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception("Usuário não encontrado no sistema.");

      _currentDriver = Driver.fromDocument(doc);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Logout do usuário atual
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _currentDriver = null;
    notifyListeners();
  }

  /// Atualiza preferências de serviço (e salva no Firestore)
  Future<void> updateServicePreferences(List<OrderType> newPreferences) async {
    if (_currentDriver == null) return;

    _currentDriver!.preferredServiceTypes = newPreferences;
    notifyListeners();

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(_currentDriver!.id)
        .update({'preferredServiceTypes': newPreferences.map((e) => e.name).toList()});
  }

  /// Atualiza preferências de pagamento (e salva no Firestore)
  Future<void> updatePaymentPreferences(List<PaymentMethod> newPreferences) async {
    if (_currentDriver == null) return;

    // Exemplo de lógica para garantir LevvaPay ativo
    final onlyDeliveryActive = _currentDriver!.preferredServiceTypes.length == 1 &&
        _currentDriver!.preferredServiceTypes.contains(OrderType.food);

    if (onlyDeliveryActive) {
      _currentDriver!.preferredPaymentMethods = [PaymentMethod.online];
    } else {
      if (!newPreferences.contains(PaymentMethod.online)) {
        newPreferences.insert(0, PaymentMethod.online);
      }
      _currentDriver!.preferredPaymentMethods = newPreferences;
    }

    notifyListeners();

    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(_currentDriver!.id)
        .update({
          'preferredPaymentMethods':
              _currentDriver!.preferredPaymentMethods.map((e) => e.name).toList(),
        });
  }

  /// Atualiza campos do perfil do motorista e salva no Firestore
  Future<void> updateDriverProfile(Map<String, dynamic> newData) async {
    if (_currentDriver == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Atualiza localmente
      _currentDriver = Driver(
        id: _currentDriver!.id,
        name: newData['name'] ?? _currentDriver!.name,
        email: newData['email'] ?? _currentDriver!.email,
        phone: newData['phone'] ?? _currentDriver!.phone,
        vehicleType: _currentDriver!.vehicleType,
        vehicleModel: newData['vehicleModel'] ?? _currentDriver!.vehicleModel,
        licensePlate: newData['licensePlate'] ?? _currentDriver!.licensePlate,
        profileImageUrl: newData['profileImageUrl'] ?? _currentDriver!.profileImageUrl,
        rating: _currentDriver!.rating,
        preferredServiceTypes: _currentDriver!.preferredServiceTypes,
        preferredPaymentMethods: _currentDriver!.preferredPaymentMethods,
        cpf: newData['cpf'] ?? _currentDriver!.cpf,
        birthDate: newData['birthDate'] ?? _currentDriver!.birthDate,
        cnhImageUrl: newData['cnhImageUrl'] ?? _currentDriver!.cnhImageUrl,
        docImageUrl: newData['docImageUrl'] ?? _currentDriver!.docImageUrl,
        cnhOpcionalImageUrl: newData['cnhOpcionalImageUrl'] ?? _currentDriver!.cnhOpcionalImageUrl,
        vehiclePhotoUrl: newData['vehiclePhotoUrl'] ?? _currentDriver!.vehiclePhotoUrl,
        vehicleColor: newData['vehicleColor'] ?? _currentDriver!.vehicleColor,
        renavam: newData['renavam'] ?? _currentDriver!.renavam,
      );

      // Salva no Firestore (só os campos alterados)
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentDriver!.id)
          .update(newData);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Atualiza dados do motorista a partir do Firestore (ex: após login ou update externo)
  Future<void> refreshDriverFromFirestore() async {
    if (_currentDriver == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(_currentDriver!.id)
        .get();
    if (doc.exists) {
      _currentDriver = Driver.fromDocument(doc);
      notifyListeners();
    }
  }
}