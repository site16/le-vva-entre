import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:levva_entregador/models/driver_model.dart';
import 'package:levva_entregador/models/order_model.dart' as mymodels;
import 'package:levva_entregador/models/vehicle_type_enum.dart';
import 'package:levva_entregador/providers/auth_provider.dart';
import 'package:levva_entregador/providers/wallet_provider.dart';
import 'package:levva_entregador/services/local_notification_service.dart';

class OrderProvider with ChangeNotifier {
  final AuthProvider authProvider;
  final WalletProvider walletProvider;

  bool _isOnline = false;
  mymodels.Order? _currentOfferedOrder;
  mymodels.Order? _activeOrder;
  List<mymodels.Order> _orderHistory = [];

  Timer? _orderAcceptanceTimer;
  int _timeToAcceptOrder = 90;
  Timer? _postCompletionTimer;
  Timer? _waitTimer;
  int _remainingWaitTime = 480;
  bool _canCancelAfterWait = false;
  bool _isDisposed = false;

  static const String _activeOrderPrefKey = 'active_ride_order';
  bool _isInitializing = true;

  mymodels.Order? _orderToRateAfterCompletion;

  StreamSubscription<DocumentSnapshot>? _activeOrderListener;

  OrderProvider(this.authProvider, this.walletProvider) {
    authProvider.addListener(_handleAuthProviderChanges);
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _loadActiveOrderFromPrefs();
    _isInitializing = false;
    if (!_isDisposed && _activeOrder != null) {
      _listenToActiveOrder(_activeOrder!.id);
      notifyListeners();
    }
    if (authProvider.currentDriver != null) {
      await fetchOrderHistory();
    }
  }

  bool get isOnline => _isOnline;
  mymodels.Order? get currentOfferedOrder => _currentOfferedOrder;
  mymodels.Order? get activeOrder => _activeOrder;
  List<mymodels.Order> get orderHistory => List.unmodifiable(_orderHistory);
  int get timeToAcceptOrder => _timeToAcceptOrder;
  int get remainingWaitTime => _remainingWaitTime;
  bool get canCancelAfterWait => _canCancelAfterWait;
  bool get isInitializing => _isInitializing;
  mymodels.Order? get orderToRate => _orderToRateAfterCompletion;

  Future<void> _saveActiveOrderToPrefs() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_activeOrder != null) {
        await prefs.setString(_activeOrderPrefKey, _activeOrder!.id);
        if (kDebugMode)
          print("OrderProvider: Pedido ativo SALVO nas prefs: ${_activeOrder!.id}");
      } else {
        await prefs.remove(_activeOrderPrefKey);
        if (kDebugMode)
          print("OrderProvider: Pedido ativo nulo, removido das prefs.");
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao salvar pedido ativo: $e");
    }
  }

  Future<void> _loadActiveOrderFromPrefs() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? orderId = prefs.getString(_activeOrderPrefKey);
      if (orderId != null && authProvider.currentDriver != null) {
        final doc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get();
        if (doc.exists) {
          _activeOrder = mymodels.Order.fromDocument(doc);
          if (_activeOrder != null &&
              (_activeOrder!.status == mymodels.OrderStatus.completed ||
                  _activeOrder!.status.name.toLowerCase().contains('cancel'))) {
            if (kDebugMode)
              print("OrderProvider: Pedido carregado já está finalizado. Limpando.");
            await _clearActiveOrderFromPrefs();
          }
        }
      } else {
        _activeOrder = null;
        if (kDebugMode)
          print("OrderProvider: Nenhum pedido ativo encontrado nas prefs.");
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao carregar pedido ativo: $e");
      _activeOrder = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_activeOrderPrefKey);
      } catch (e2) {
        if (kDebugMode)
          print("OrderProvider: Erro ao tentar limpar prefs corrompidas: $e2");
      }
    }
  }

  Future<void> _clearActiveOrderFromPrefs() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeOrderPrefKey);
      _activeOrder = null;
      _stopActiveOrderListener();
      if (kDebugMode)
        print("OrderProvider: Pedido ativo LIMPO das prefs e da memória.");
    } catch (e) {
      if (kDebugMode)
        print("OrderProvider: Erro ao limpar pedido ativo das prefs: $e");
    }
  }

  void rehydratePreviousState(OrderProvider? previousProvider) {
    if (_isDisposed || previousProvider == null) return;
    _isOnline = previousProvider._isOnline;
    _orderHistory = List<mymodels.Order>.from(previousProvider._orderHistory);
    if (kDebugMode)
      print("OrderProvider: Estado reidratado. _isOnline: $_isOnline");
    if (_isOnline &&
        _activeOrder == null &&
        _currentOfferedOrder == null &&
        authProvider.currentDriver != null) {
      _searchForOrders();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stopActiveOrderListener();
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
      if (_isDisposed ||
          _activeOrder?.status != mymodels.OrderStatus.awaitingPickup) {
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

  /// Escuta o pedido ativo em tempo real no Firestore
  void _listenToActiveOrder(String orderId) {
    _activeOrderListener?.cancel();
    _activeOrderListener = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (_isDisposed) return;
      if (doc.exists) {
        final updatedOrder = mymodels.Order.fromDocument(doc);
        _activeOrder = updatedOrder;
        // Se o status mudou para completed/cancel, limpe prefs e pare listener
        if (updatedOrder.status == mymodels.OrderStatus.completed ||
            updatedOrder.status.name.toLowerCase().contains('cancel')) {
          _orderHistory.insert(0, updatedOrder);
          _orderToRateAfterCompletion =
              updatedOrder.status == mymodels.OrderStatus.completed
                  ? updatedOrder
                  : null;
          _clearActiveOrderFromPrefs();
        }
        notifyListeners();
      } else {
        _activeOrder = null;
        _clearActiveOrderFromPrefs();
        notifyListeners();
      }
    });
  }

  void _stopActiveOrderListener() {
    _activeOrderListener?.cancel();
    _activeOrderListener = null;
  }

  /// Atualiza o status do pedido ativo no Firestore (sempre atualize campos extras!)
  Future<void> updateActiveOrderStatus(mymodels.OrderStatus newStatus) async {
    if (_isDisposed || _activeOrder == null) return;

    final mymodels.Order orderToUpdate = _activeOrder!;
    final mymodels.OrderStatus oldStatus = orderToUpdate.status;

    if (newStatus == mymodels.OrderStatus.awaitingPickup) {
      orderToUpdate.waitingSince = DateTime.now();
      _startWaitTimer();
    } else if (oldStatus == mymodels.OrderStatus.awaitingPickup ||
        newStatus == mymodels.OrderStatus.completed ||
        newStatus.name.toLowerCase().contains('cancel')) {
      _stopWaitTimer();
    }

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderToUpdate.id)
          .update({
            'status': newStatus.name,
            if (newStatus == mymodels.OrderStatus.awaitingPickup)
              'waitingSince': Timestamp.fromDate(orderToUpdate.waitingSince!),
            if (authProvider.currentDriver != null) ...{
              'driverId': authProvider.currentDriver!.id,
              'driverName': authProvider.currentDriver!.name,
              'driverVehicleDetails': authProvider.currentDriver!.vehicleDetails,
              'driverProfileImageUrl': authProvider.currentDriver!.profileImageUrl,
            }
          });
      orderToUpdate.status = newStatus;
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao atualizar status: $e");
      return;
    }

    bool orderHasEnded =
        newStatus == mymodels.OrderStatus.completed ||
        newStatus.name.toLowerCase().contains('cancel');

    if (orderHasEnded) {
      if (kDebugMode)
        print(
          "OrderProvider: Pedido ${orderToUpdate.id} movido para o histórico com status: $newStatus.",
        );
      _orderHistory.insert(0, orderToUpdate);
      if (newStatus == mymodels.OrderStatus.completed) {
        walletProvider.addTransactionForOrderCompletion(
          orderId: orderToUpdate.id,
          amount: orderToUpdate.estimatedValue,
          date: DateTime.now(),
          paidOnline:
              orderToUpdate.paymentMethod == mymodels.PaymentMethod.online,
        );
        _orderToRateAfterCompletion = orderToUpdate;
      }
      await _clearActiveOrderFromPrefs();
    } else {
      await _saveActiveOrderToPrefs();
    }

    if (!_isDisposed) notifyListeners();
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
    try {
      final doc = FirebaseFirestore.instance.collection('orders').doc(orderId);
      await doc.collection('avaliacoes').add({
        'rating': rating,
        'motivos': motivos,
        'comentario': comentario,
        'bloquear': bloquear,
        'avaliadoUserId': avaliadoUserId,
        'avaliadorId': avaliadorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _orderToRateAfterCompletion = null;
      if (_isOnline &&
          authProvider.currentDriver != null &&
          _activeOrder == null &&
          _currentOfferedOrder == null) {
        _searchForOrders();
      }
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao enviar avaliação: $e");
    }
  }

  void clearOrderFromRating() {
    if (_isDisposed) return;
    _orderToRateAfterCompletion = null;
    if (_isOnline &&
        authProvider.currentDriver != null &&
        _activeOrder == null &&
        _currentOfferedOrder == null) {
      _searchForOrders();
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<bool> confirmDeliveryWithCode(String code) async {
    if (_isDisposed || _activeOrder == null) return false;

    try {
      // Confirmação de entrega: atualiza status no pedido (pode adicionar mais lógica se quiser)
      if (_activeOrder!.confirmationCode == code) {
        await updateActiveOrderStatus(mymodels.OrderStatus.completed);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao confirmar entrega: $e");
      return false;
    }
  }

  /// Aceita o pedido ofertado e atualiza no Firestore, passa a escutar o pedido (sempre atualize campos extras!)
  Future<void> acceptOfferedOrder() async {
    if (_isDisposed || _currentOfferedOrder == null) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(_currentOfferedOrder!.id);

      await docRef.update({
        'status': mymodels.OrderStatus.toPickup.name,
        'driverId': authProvider.currentDriver?.id,
        'driverName': authProvider.currentDriver?.name,
        'driverVehicleDetails': authProvider.currentDriver?.vehicleDetails,
        'driverProfileImageUrl': authProvider.currentDriver?.profileImageUrl,
      });
      _activeOrder = _currentOfferedOrder;
      _activeOrder!.status = mymodels.OrderStatus.toPickup;
      _currentOfferedOrder = null;
      await _saveActiveOrderToPrefs();
      _listenToActiveOrder(_activeOrder!.id);
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao aceitar pedido: $e");
    }
  }

  void _handleAuthProviderChanges() async {
    if (_isDisposed) return;
    if (authProvider.currentDriver == null) {
      if (_isOnline) {
        toggleOnlineStatus(false, forceUpdate: true);
      }
      _activeOrder = null;
      _currentOfferedOrder = null;
      _stopActiveOrderListener();
      await _clearActiveOrderFromPrefs();
      if (!_isDisposed) notifyListeners();
    } else {
      _isInitializing = true;
      notifyListeners();
      await _loadActiveOrderFromPrefs();
      if (_activeOrder != null) {
        _listenToActiveOrder(_activeOrder!.id);
      }
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
    await updateActiveOrderStatus(mymodels.OrderStatus.returningToStore);
  }

  Future<void> confirmPaymentReceivedAndComplete() async {
    await updateActiveOrderStatus(mymodels.OrderStatus.completed);
  }

  Future<void> toggleOnlineStatus(
    bool online, {
    bool forceUpdate = false,
  }) async {
    if (_isDisposed) return;
    if (authProvider.currentDriver == null && online) return;
    if (_isOnline == online && !forceUpdate) return;

    // ATUALIZA O STATUS ONLINE NO FIRESTORE
    try {
      if (authProvider.currentDriver != null) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(authProvider.currentDriver!.id)
            .update({'isOnline': online});
        if (kDebugMode)
          print('OrderProvider: isOnline atualizado no Firestore: $online');
      }
    } catch (e) {
      if (kDebugMode)
        print('OrderProvider: ERRO ao atualizar isOnline no Firestore: $e');
    }

    _isOnline = online;
    if (kDebugMode)
      print("OrderProvider: Status online alterado para $_isOnline");

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

  bool _isOrderSuitable(mymodels.Order order, Driver driver) {
    if (!driver.preferredServiceTypes.contains(order.type)) return false;
    if (!order.suitableVehicleTypes.contains(driver.vehicleType)) return false;
    if (driver.vehicleType == VehicleType.bike &&
        order.type == mymodels.OrderType.moto)
      return false;
    if (!driver.preferredPaymentMethods.contains(order.paymentMethod))
      return false;
    return true;
  }

  /// Busca pedidos disponíveis no Firestore e oferta um adequado
  void _searchForOrders() async {
    if (_isDisposed ||
        !_isOnline ||
        _currentOfferedOrder != null ||
        _activeOrder != null ||
        authProvider.currentDriver == null) {
      return;
    }

    _postCompletionTimer?.cancel();
    if (kDebugMode) print("OrderProvider: Buscando pedidos...");

    try {
      // Busca todos os pedidos com status 'pendingAcceptance' (ou similar)
      final snapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where(
                'status',
                isEqualTo: mymodels.OrderStatus.pendingAcceptance.name,
              )
              .get();

      mymodels.Order? foundOrder;
      for (var doc in snapshot.docs) {
        final ord = mymodels.Order.fromDocument(doc);
        if (_isOrderSuitable(ord, authProvider.currentDriver!)) {
          foundOrder = ord;
          break;
        }
      }

      if (foundOrder != null) {
        _currentOfferedOrder = foundOrder;
        _timeToAcceptOrder = 90;
        _startOrderAcceptanceTimer();
        LocalNotificationService.showNotification(
          title: "Novo pedido disponível!",
          body:
              "Pedido de ${foundOrder.type.name} para ${foundOrder.pickupAddress}",
        );
        if (!_isDisposed) notifyListeners();
      } else {
        if (kDebugMode)
          print(
            "OrderProvider: Nenhum pedido adequado encontrado, próxima busca em 7s.",
          );
        _postCompletionTimer = Timer(
          const Duration(seconds: 7),
          _searchForOrders,
        );
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao buscar pedidos: $e");
      _postCompletionTimer = Timer(
        const Duration(seconds: 7),
        _searchForOrders,
      );
    }
  }

  void _startOrderAcceptanceTimer() {
    if (_isDisposed) return;
    _orderAcceptanceTimer?.cancel();
    _orderAcceptanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _currentOfferedOrder == null) {
        timer.cancel();
        return;
      }
      if (_timeToAcceptOrder > 0) {
        _timeToAcceptOrder--;
        if (!_isDisposed) notifyListeners();
      } else {
        if (kDebugMode)
          print("OrderProvider: Tempo para aceitar esgotado. Rejeitando.");
        rejectOfferedOrder(autoRejected: true);
      }
    });
  }

  /// Rejeita o pedido ofertado (atualiza Firestore e move para histórico)
  Future<void> rejectOfferedOrder({bool autoRejected = false}) async {
    if (_isDisposed || _currentOfferedOrder == null) return;

    final mymodels.Order rejectedOrder = _currentOfferedOrder!;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(rejectedOrder.id)
          .update({
            'status': autoRejected
                ? mymodels.OrderStatus.cancelledBySystem.name
                : mymodels.OrderStatus.cancelledByDriver.name,
            'driverId': authProvider.currentDriver?.id,
          });
      rejectedOrder.status = autoRejected
          ? mymodels.OrderStatus.cancelledBySystem
          : mymodels.OrderStatus.cancelledByDriver;
      _orderHistory.insert(0, rejectedOrder);
      _currentOfferedOrder = null;
      if (!_isDisposed) {
        notifyListeners();
        _searchForOrders();
      }
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao rejeitar pedido: $e");
    }
  }

  /// Solicita cancelamento do pedido ativo (atualiza campo no Firestore)
  Future<void> requestCancelActiveOrder(String reason) async {
    if (_isDisposed || _activeOrder == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(_activeOrder!.id)
          .update({
            'status': mymodels.OrderStatus.cancellationRequested.name,
            'cancelReason': reason,
          });
      await updateActiveOrderStatus(mymodels.OrderStatus.cancellationRequested);
    } catch (e) {
      if (kDebugMode)
        print("OrderProvider: Erro ao solicitar cancelamento: $e");
    }
  }

  /// Busca histórico de pedidos do motorista pelo Firestore
  Future<void> fetchOrderHistory() async {
    if (_isDisposed || authProvider.currentDriver == null) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('driverId', isEqualTo: authProvider.currentDriver!.id)
              .orderBy('creationTime', descending: true)
              .get();
      List<mymodels.Order> parsed =
          snapshot.docs.map((doc) => mymodels.Order.fromDocument(doc)).toList();
      _orderHistory = parsed;
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      if (kDebugMode) print("OrderProvider: Erro ao buscar histórico: $e");
    }
  }
}