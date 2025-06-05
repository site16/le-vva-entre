import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:levva_entregador/models/driver_model.dart';
import 'package:levva_entregador/models/order_model.dart';
import 'package:levva_entregador/models/vehicle_type_enum.dart';
import 'package:levva_entregador/providers/auth_provider.dart';
import 'package:levva_entregador/providers/wallet_provider.dart';
import 'package:levva_entregador/services/local_notification_service.dart';

class OrderProvider with ChangeNotifier {
  final AuthProvider authProvider;
  final WalletProvider walletProvider;

  bool _isOnline = false;
  Order? _currentOfferedOrder;
  Order? _activeOrder;
  List<Order> _orderHistory = [];

  Timer? _orderAcceptanceTimer;
  int _timeToAcceptOrder = 90;
  Timer? _postCompletionTimer;
  Timer? _waitTimer;
  int _remainingWaitTime = 480;
  bool _canCancelAfterWait = false;
  bool _isDisposed = false;

  static const String _activeOrderPrefKey = 'active_ride_order';
  bool _isInitializing = true;

  Order? _orderToRateAfterCompletion;

  OrderProvider(this.authProvider, this.walletProvider) {
    authProvider.addListener(_handleAuthProviderChanges);
    _initializeProvider();
  }
  
  Future<void> _initializeProvider() async {
    await _loadActiveOrderFromPrefs();
    _isInitializing = false;
    if (!_isDisposed && _activeOrder != null) {
      notifyListeners();
    }
  }

  bool get isOnline => _isOnline;
  Order? get currentOfferedOrder => _currentOfferedOrder;
  Order? get activeOrder => _activeOrder;
  List<Order> get orderHistory => List.unmodifiable(_orderHistory);
  int get timeToAcceptOrder => _timeToAcceptOrder;
  int get remainingWaitTime => _remainingWaitTime;
  bool get canCancelAfterWait => _canCancelAfterWait;
  bool get isInitializing => _isInitializing;
  Order? get orderToRate => _orderToRateAfterCompletion;

  final List<Order> _availableOrdersPool = [
    Order(id: 'orderP001', type: OrderType.package, pickupAddress: 'Loja Pequena - Av. C, 3', deliveryAddress: 'Escritório Y - Av. D, 4', estimatedValue: 7.00, distanceToPickup: 0.5, routeDistance: 1.5, creationTime: DateTime.now(), customerName: 'Cliente Y', paymentMethod: PaymentMethod.online, recipientPhoneNumber: "34999991234"),
    Order(id: 'orderF001', type: OrderType.food, pickupAddress: 'Pizza Place - Rua A, 1', deliveryAddress: 'Casa Cliente X - Rua B, 2', estimatedValue: 10.00, distanceToPickup: 1.0, routeDistance: 2.0, creationTime: DateTime.now(), storeName: 'Pizza Place', items: ['Pizza P'], paymentMethod: PaymentMethod.online, recipientPhoneNumber: "34988885678"),
    Order(id: 'orderF002', type: OrderType.food, pickupAddress: 'Burger Joint - Rua G, 7', deliveryAddress: 'Apto Cliente Z - Rua H, 8', estimatedValue: 12.50, distanceToPickup: 1.2, routeDistance: 2.5, creationTime: DateTime.now(), storeName: 'Burger Joint', items: ['X-Tudo'], paymentMethod: PaymentMethod.cash, recipientPhoneNumber: "34911112222"),
    Order(id: 'orderM001', type: OrderType.moto, pickupAddress: 'Ponto Z - Rua E, 5', deliveryAddress: 'Destino W - Rua F, 6', estimatedValue: 15.00, distanceToPickup: 2.0, routeDistance: 5.0, creationTime: DateTime.now(), customerName: 'Passageiro W', paymentMethod: PaymentMethod.cash, recipientPhoneNumber: "34933334444"),
    Order(id: 'orderM002', type: OrderType.moto, pickupAddress: 'Shopping - Av. Brasil', deliveryAddress: 'Centro - Praça da Matriz', estimatedValue: 9.00, distanceToPickup: 1.5, routeDistance: 3.0, creationTime: DateTime.now(), customerName: 'Maria', paymentMethod: PaymentMethod.online, recipientPhoneNumber: "34955556666"),
    Order(id: 'orderF003_cardMachine', type: OrderType.food, pickupAddress: 'Restaurante Moderno - Av. Principal, 100', deliveryAddress: 'Empresa Tech - Rua Inovação, 200', estimatedValue: 25.75, distanceToPickup: 0.8, routeDistance: 3.2, creationTime: DateTime.now().subtract(const Duration(minutes: 5)), storeName: 'Restaurante Moderno', items: ['Prato Executivo', 'Suco Natural'], paymentMethod: PaymentMethod.cardMachine, recipientPhoneNumber: "34977778888"),
  ];
  int _nextOrderIndex = 0;

  Future<void> _saveActiveOrderToPrefs() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeOrder != null) {
        await prefs.setString(_activeOrderPrefKey, jsonEncode(_activeOrder!.toJson()));
        if (kDebugMode) print("OrderProvider: Pedido ativo SALVO nas prefs: ${_activeOrder!.id}");
      } else {
        await prefs.remove(_activeOrderPrefKey);
        if (kDebugMode) print("OrderProvider: Pedido ativo nulo, removido das prefs.");
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao salvar pedido ativo: $e");
    }
  }

  Future<void> _loadActiveOrderFromPrefs() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? orderJson = prefs.getString(_activeOrderPrefKey);
      if (orderJson != null) {
        _activeOrder = Order.fromJson(jsonDecode(orderJson));
        if (kDebugMode) print("OrderProvider: Pedido ativo CARREGADO das prefs: ${_activeOrder?.id}, Status: ${_activeOrder?.status}, Código: ${_activeOrder?.confirmationCode}");

        if (_activeOrder != null && (_activeOrder!.status == OrderStatus.completed || _activeOrder!.status.name.toLowerCase().contains('cancel'))) {
          if (kDebugMode) print("OrderProvider: Pedido carregado já está finalizado. Limpando.");
          await _clearActiveOrderFromPrefs(); 
        }
      } else {
        _activeOrder = null;
        if (kDebugMode) print("OrderProvider: Nenhum pedido ativo encontrado nas prefs.");
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao carregar pedido ativo: $e");
      _activeOrder = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_activeOrderPrefKey);
      } catch (e2) {
        if (kDebugMode) print("OrderProvider: Erro ao tentar limpar prefs corrompidas: $e2");
      }
    }
  }

  Future<void> _clearActiveOrderFromPrefs() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeOrderPrefKey);
      _activeOrder = null; 
      if (kDebugMode) print("OrderProvider: Pedido ativo LIMPO das prefs e da memória.");
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao limpar pedido ativo das prefs: $e");
    }
  }

  void rehydratePreviousState(OrderProvider? previousProvider) {
    if (_isDisposed || previousProvider == null) return;
    _isOnline = previousProvider._isOnline;
    _orderHistory = List<Order>.from(previousProvider._orderHistory);
    if (kDebugMode) print("OrderProvider: Estado reidratado. _isOnline: $_isOnline");
    if (_isOnline && _activeOrder == null && _currentOfferedOrder == null && authProvider.currentDriver != null) {
      _searchForOrders();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _orderAcceptanceTimer?.cancel();
    _postCompletionTimer?.cancel();
    _waitTimer?.cancel();
    authProvider.removeListener(_handleAuthProviderChanges);
    super.dispose();
  }

  void _startWaitTimer() {
    if (_isDisposed) return;
    _waitTimer?.cancel();
    _remainingWaitTime = 480;
    _canCancelAfterWait = false;
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _activeOrder?.status != OrderStatus.awaitingPickup) {
        timer.cancel();
        return;
      }
      if (_remainingWaitTime > 0) {
        _remainingWaitTime--;
      } else {
        _canCancelAfterWait = true;
        timer.cancel();
      }
      if (!_isDisposed) notifyListeners();
    });
  }

  void _stopWaitTimer() {
    if (_isDisposed) return;
    _waitTimer?.cancel();
    if (_canCancelAfterWait || _remainingWaitTime < 480) {
      _canCancelAfterWait = false;
      _remainingWaitTime = 480;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> _simulateStoreConfirmation() async {
    if (_isDisposed || _activeOrder == null || _activeOrder!.status != OrderStatus.awaitingStoreConfirmation) return;
    
    final orderIdToConfirm = _activeOrder!.id;
    await Future.delayed(const Duration(seconds: 5)); 

    if (_isDisposed || _activeOrder?.id != orderIdToConfirm || _activeOrder?.status != OrderStatus.awaitingStoreConfirmation) {
      return;
    }
    await updateActiveOrderStatus(OrderStatus.completed);
  }

  Future<void> updateActiveOrderStatus(OrderStatus newStatus) async {
    if (_isDisposed || _activeOrder == null) return;

    final Order orderToUpdate = _activeOrder!;
    final OrderStatus oldStatus = orderToUpdate.status;

    if (newStatus == OrderStatus.awaitingPickup) {
      orderToUpdate.waitingSince = DateTime.now();
      _startWaitTimer();
    } else if (oldStatus == OrderStatus.awaitingPickup || newStatus == OrderStatus.completed || newStatus.name.toLowerCase().contains('cancel')) {
      _stopWaitTimer();
    }
    
    orderToUpdate.status = newStatus;

    bool orderHasEnded = newStatus == OrderStatus.completed || newStatus.name.toLowerCase().contains('cancel');

    if (orderHasEnded) {
      if (kDebugMode) print("OrderProvider: Pedido ${orderToUpdate.id} movido para o histórico com status: $newStatus.");
      _orderHistory.insert(0, orderToUpdate);
      if (newStatus == OrderStatus.completed) {
        walletProvider.addTransactionForOrderCompletion(orderToUpdate);
        _orderToRateAfterCompletion = orderToUpdate;
      }
      await _clearActiveOrderFromPrefs();
    } else {
      await _saveActiveOrderToPrefs();
    }
    
    if (!_isDisposed) notifyListeners();

    if (newStatus == OrderStatus.awaitingStoreConfirmation) {
      _simulateStoreConfirmation();
    }

    if (orderHasEnded && newStatus != OrderStatus.completed) {
      _postCompletionTimer?.cancel();
      _postCompletionTimer = Timer(const Duration(seconds: 3), () {
        if (_isOnline && authProvider.currentDriver != null && _activeOrder == null && _currentOfferedOrder == null) { 
          _searchForOrders();
        }
      });
    }
  }

  Future<void> enviarAvaliacaoCliente({
    required String orderId,
    required int rating,
    required List<String> motivos,
    required String comentario,
    required bool bloquear,
    String? avaliadoUserId,
    String? avaliadorId,
  }) async {
    debugPrint('[SIMULAÇÃO] Avaliação enviada: '
        'orderId=$orderId, rating=$rating, motivos=$motivos, '
        'comentario=$comentario, bloquear=$bloquear, '
        'avaliadoUserId=$avaliadoUserId, avaliadorId=$avaliadorId');
    _orderToRateAfterCompletion = null;
    if (_isOnline && authProvider.currentDriver != null && _activeOrder == null && _currentOfferedOrder == null) {
      _searchForOrders();
    }
    if (!_isDisposed) notifyListeners();
  }

  void clearOrderFromRating() {
    if (_isDisposed) return;
    if (kDebugMode) print("OrderProvider: Pedido ${_orderToRateAfterCompletion?.id} pulado/removido da avaliação.");
    _orderToRateAfterCompletion = null;
    if (_isOnline && authProvider.currentDriver != null && _activeOrder == null && _currentOfferedOrder == null) {
      _searchForOrders();
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<bool> confirmDeliveryWithCode(String code) async {
    if (_isDisposed || _activeOrder == null) return false;
    
    final String? correctCode = _activeOrder!.confirmationCode;

    if (correctCode == null) {
      if (kDebugMode) print("OrderProvider: Não foi possível gerar o código (sem número de telefone).");
      return false;
    }

    if (kDebugMode) print("OrderProvider: Validando código '$code' contra '$correctCode' do pedido ${_activeOrder!.id}.");

    if (correctCode == code) {
      if (kDebugMode) print("OrderProvider: Código CORRETO. Finalizando o pedido.");
      await updateActiveOrderStatus(OrderStatus.completed);
      return true;
    } else {
      if (kDebugMode) print("OrderProvider: Código INCORRETO. Nenhuma alteração de estado será feita.");
      return false;
    }
  }

  Future<void> acceptOfferedOrder() async {
    if (_isDisposed || _currentOfferedOrder == null) return;
    
    if (kDebugMode) print("OrderProvider: Pedido ${_currentOfferedOrder!.id} aceito.");
    _orderAcceptanceTimer?.cancel();

    _activeOrder = _currentOfferedOrder;
    _activeOrder!.status = OrderStatus.toPickup;
    _currentOfferedOrder = null;
    
    await _saveActiveOrderToPrefs();
    if (!_isDisposed) notifyListeners();
  }
  
  void _handleAuthProviderChanges() async {
    if (_isDisposed) return;
    if (authProvider.currentDriver == null) { 
      if (_isOnline) {
        toggleOnlineStatus(false, forceUpdate: true); 
      }
      _activeOrder = null; 
      _currentOfferedOrder = null;
      await _clearActiveOrderFromPrefs();
      if (!_isDisposed) notifyListeners();
    } else { 
      _isInitializing = true;
      notifyListeners();
      await _loadActiveOrderFromPrefs();
      _isInitializing = false;
      if (!_isDisposed) {
        notifyListeners();
        if (_isOnline && _activeOrder == null && _currentOfferedOrder == null) {
          _searchForOrders();
        }
      }
    }
  }

  Future<void> setOrderToReturningToStore() async {
    await updateActiveOrderStatus(OrderStatus.returningToStore);
  }

  Future<void> confirmPaymentReceivedAndComplete() async {
    await updateActiveOrderStatus(OrderStatus.completed);
  }

  void toggleOnlineStatus(bool online, {bool forceUpdate = false}) {
    if (_isDisposed) return;
    if (authProvider.currentDriver == null && online) return; 
    if (_isOnline == online && !forceUpdate) return; 
    
    _isOnline = online;
    if (kDebugMode) print("OrderProvider: Status online alterado para $_isOnline");

    if (_isOnline) {
      if (_activeOrder == null && _currentOfferedOrder == null) {
        _searchForOrders();
      }
    } else {
      _currentOfferedOrder = null; 
      _orderAcceptanceTimer?.cancel();
      _postCompletionTimer?.cancel(); 
    }
    if (!_isDisposed) notifyListeners();
  }

  bool _isOrderSuitable(Order order, Driver driver) {
    if (!driver.preferredServiceTypes.contains(order.type)) return false;
    if (!order.suitableVehicleTypes.contains(driver.vehicleType)) return false;
    if (driver.vehicleType == VehicleType.bike && order.type == OrderType.moto) return false;
    if (!driver.preferredPaymentMethods.contains(order.paymentMethod)) return false;
    return true;
  }

  void _searchForOrders() {
    if (_isDisposed || !_isOnline || _currentOfferedOrder != null || _activeOrder != null || authProvider.currentDriver == null) {
      return;
    }

    _postCompletionTimer?.cancel();
    if (kDebugMode) print("OrderProvider: Buscando pedidos...");

    Future.delayed(Duration(seconds: 2 + (_nextOrderIndex % 3)), () {
      if (_isDisposed || !_isOnline || _currentOfferedOrder != null || _activeOrder != null || authProvider.currentDriver == null) {
        return;
      }

      Order? foundOrder;
      int searchAttempts = 0;
      int initialIndex = _nextOrderIndex; 

      do {
        Order potentialOrder = _availableOrdersPool[_nextOrderIndex];
        bool alreadyProcessed = _orderHistory.any((histOrder) => histOrder.id == potentialOrder.id && DateTime.now().difference(histOrder.creationTime).inMinutes < 30); 

        if (!alreadyProcessed && _isOrderSuitable(potentialOrder, authProvider.currentDriver!)) {
          foundOrder = potentialOrder;
        }
        _nextOrderIndex = (_nextOrderIndex + 1) % _availableOrdersPool.length;
        searchAttempts++;
      } while (foundOrder == null && searchAttempts < _availableOrdersPool.length && _nextOrderIndex != initialIndex);

      if (foundOrder != null) {
        if (kDebugMode) print("OrderProvider: Pedido ${foundOrder.id} encontrado e ofertado.");
        _currentOfferedOrder = foundOrder;
        _timeToAcceptOrder = 90;
        _startOrderAcceptanceTimer();
        // --- SIMULAÇÃO DE NOTIFICAÇÃO PUSH ---
        LocalNotificationService.showNotification(
          title: "Novo pedido disponível!",
          body: "Pedido de ${foundOrder.type.name} para ${foundOrder.pickupAddress}",
        );
        if (!_isDisposed) notifyListeners();
      } else {
        if (kDebugMode) print("OrderProvider: Nenhum pedido adequado encontrado, próxima busca em 7s.");
        _postCompletionTimer = Timer(const Duration(seconds: 7), _searchForOrders);
      }
    });
  }

  void _startOrderAcceptanceTimer() {
    if (_isDisposed) return;
    _orderAcceptanceTimer?.cancel();
    _orderAcceptanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _currentOfferedOrder == null) {
        timer.cancel(); return;
      }
      if (_timeToAcceptOrder > 0) {
        _timeToAcceptOrder--;
        if (!_isDisposed) notifyListeners();
      } else {
        if (kDebugMode) print("OrderProvider: Tempo para aceitar esgotado. Rejeitando.");
        rejectOfferedOrder(autoRejected: true);
      }
    });
  }

  Future<void> rejectOfferedOrder({bool autoRejected = false}) async {
    if (_isDisposed || _currentOfferedOrder == null) return;

    final Order rejectedOrder = _currentOfferedOrder!; 
    if (kDebugMode) print("OrderProvider: Pedido ${rejectedOrder.id} rejeitado ${autoRejected ? '(auto)' : ''}.");
    
    _orderAcceptanceTimer?.cancel();
    
    rejectedOrder.status = autoRejected ? OrderStatus.cancelledBySystem : OrderStatus.cancelledByDriver;
    
    _orderHistory.insert(0, rejectedOrder);
    _currentOfferedOrder = null; 
    
    if (!_isDisposed) {
      notifyListeners(); 
      _searchForOrders(); 
    }
  }

  Future<void> requestCancelActiveOrder(String reason) async {
    if (_isDisposed || _activeOrder == null) return;
    if (kDebugMode) print("OrderProvider: Solicitação de cancelamento para pedido ${_activeOrder!.id} com motivo: $reason");
    await updateActiveOrderStatus(OrderStatus.cancellationRequested);
  }

  Future<void> fetchOrderHistory() async {
    if (_isDisposed) return;
    if (kDebugMode) print("OrderProvider: Histórico de pedidos 'buscado'.");
  }
}