// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/driver_model.dart';
import '../models/order_model.dart'; // Para OrderType e PaymentMethod
import '../models/vehicle_type_enum.dart'; // Para VehicleType

class AuthProvider with ChangeNotifier {
  Driver? _currentDriver;
  bool _isLoading = false;

  Driver? get currentDriver => _currentDriver;
  bool get isAuthenticated => _currentDriver != null;
  bool get isLoading => _isLoading;

  Future<bool> login(String cpf, String password) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));

    String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Simulação de login. Em um app real, você buscaria os dados do Driver do backend
    // e usaria Driver.fromMap(apiData, driverId) para criar o objeto _currentDriver.
    // A lógica de `Driver.fromMap` já trata a inicialização de preferredPaymentMethods.

    if (cleanCpf == "11111111111" && password == "12345678") {
      _currentDriver = Driver(
        id: 'driverMoto001',
        name: 'Carlos Entregador (Moto)',
        email: 'moto@example.com',
        phone: '(31) 98765-4321',
        vehicleType: VehicleType.moto,
        vehicleModel: 'Honda CG 160',
        licensePlate: 'LEV-0101',
        rating: 4.8,
        profileImageUrl: 'https://via.placeholder.com/150/0000FF/FFFFFF?Text=CM',
        preferredServiceTypes: [OrderType.food, OrderType.package, OrderType.moto],
        // preferredPaymentMethods será inicializado com o padrão do construtor de Driver
        // que é [PaymentMethod.online, PaymentMethod.cash, PaymentMethod.cardMachine]
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (cleanCpf == "22222222222" && password == "12345678") {
      _currentDriver = Driver(
        id: 'driverBike002',
        name: 'Ana Entregadora (Bike)',
        email: 'bike@example.com',
        phone: '(31) 91234-5678',
        vehicleType: VehicleType.bike,
        vehicleModel: 'Caloi Explorer',
        licensePlate: 'BIK-0202',
        rating: 4.9,
        profileImageUrl: 'https://via.placeholder.com/150/00FF00/FFFFFF?Text=AB',
        preferredServiceTypes: [OrderType.food, OrderType.package],
        // preferredPaymentMethods será inicializado com o padrão do construtor de Driver
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      throw Exception("CPF ou senha inválidos.");
    }
  }

  Future<void> logout() async {
    _currentDriver = null;
    notifyListeners();
  }

  Future<void> updateServicePreferences(List<OrderType> newPreferences) async {
    if (_currentDriver == null) return;
    _currentDriver!.preferredServiceTypes = newPreferences;
    notifyListeners();
    if (kDebugMode) {
      print("AuthProvider: Preferências de serviço atualizadas para: $newPreferences");
    }
    // Em um app real, você salvaria isso no backend.
  }

  Future<void> updatePaymentPreferences(List<PaymentMethod> newPreferences) async {
    if (_currentDriver == null) return;

    // Regra de negócio: PaymentMethod.online (LevvaPay) é sempre aceito.
    if (!newPreferences.contains(PaymentMethod.online)) {
      newPreferences.insert(0, PaymentMethod.online);
    }

    _currentDriver!.preferredPaymentMethods = newPreferences;
    notifyListeners();
    if (kDebugMode) {
      print("AuthProvider: Preferências de pagamento atualizadas para: $newPreferences");
    }
    // Em um app real, você salvaria isso no backend.
  }

  Future<void> updateDriverProfile(Map<String, dynamic> newData) async {
    if (_currentDriver == null) return;
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1)); 

    // Em um app real, você enviaria newData para o backend e receberia o Driver atualizado.
    // Por enquanto, estamos recriando o objeto Driver localmente.
    _currentDriver = Driver(
      id: _currentDriver!.id,
      name: newData['name'] ?? _currentDriver!.name,
      email: _currentDriver!.email, 
      phone: newData['phone'] ?? _currentDriver!.phone,
      vehicleType: _currentDriver!.vehicleType, 
      vehicleModel: newData['vehicleModel'] ?? _currentDriver!.vehicleModel,
      licensePlate: newData['licensePlate'] ?? _currentDriver!.licensePlate,
      profileImageUrl: newData['profileImageUrl'] ?? _currentDriver!.profileImageUrl,
      rating: _currentDriver!.rating, 
      preferredServiceTypes: _currentDriver!.preferredServiceTypes, 
      preferredPaymentMethods: _currentDriver!.preferredPaymentMethods, // Mantém as preferências atuais
    );
    _isLoading = false;
    notifyListeners();
  }
}