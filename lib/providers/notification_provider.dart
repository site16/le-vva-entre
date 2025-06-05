import 'package:flutter/material.dart';
import 'package:levva_entregador/models/app_notification.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.reversed);

  int get unreadCount =>
      _notifications.where((n) => !n.read).length;

  void addNotification(AppNotification notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  void addSystemNotification({
    required String title,
    required String body,
    AppNotificationType type = AppNotificationType.system,
    Map<String, dynamic>? data,
  }) {
    _notifications.add(AppNotification(
      id: const Uuid().v4(),
      title: title,
      body: body,
      date: DateTime.now(),
      type: type,
      data: data,
    ));
    notifyListeners();
  }

  // Adiciona notificação de solicitação de saque
  void addWithdrawalNotification({
    required double requested,
    required double net,
    required double fees,
    String? status,
  }) {
    _notifications.add(AppNotification(
      id: const Uuid().v4(),
      title: 'Solicitação de Saque',
      body: 'Seu saque foi solicitado com sucesso!',
      date: DateTime.now(),
      type: AppNotificationType.withdrawalRequest,
      data: {
        'requested': 'R\$${requested.toStringAsFixed(2)}',
        'net': 'R\$${net.toStringAsFixed(2)}',
        'fees': 'R\$${fees.toStringAsFixed(2)}',
        'status': status ?? "Pendente",
      },
    ));
    notifyListeners();
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].read) {
      _notifications[index] = _notifications[index].copyWith(read: true);
      notifyListeners();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}