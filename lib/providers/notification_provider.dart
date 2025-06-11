// lib/providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:levva_entregador/models/app_notification.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  // ### CORREÇÃO: userId agora pode ser nulo ###
  final String? userId;
  final FirebaseFirestore firestore;

  List<AppNotification> _notifications = [];

  // ### CORREÇÃO: O construtor aceita um userId que pode ser nulo ###
  NotificationProvider({this.userId, FirebaseFirestore? firestoreInstance})
      : firestore = firestoreInstance ?? FirebaseFirestore.instance {
    // Só busca as notificações se houver um usuário logado
    if (userId != null && userId!.isNotEmpty) {
      fetchNotifications();
    }
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications.reversed);

  int get unreadCount => _notifications.where((n) => !n.read).length;

  /// Busca notificações do Firestore
  // ### CORREÇÃO: O método agora usa o userId da classe, sem precisar de parâmetro ###
  Future<void> fetchNotifications() async {
    // Impede a execução se não houver ID de usuário (usuário deslogado)
    if (userId == null || userId!.isEmpty) {
      _notifications = [];
      notifyListeners();
      return;
    }
    try {
       final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .get();

      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      // Tratar erro, se necessário
      print("Erro ao buscar notificações: $e");
    }
  }

  /// Adiciona notificação (real) no Firestore
  Future<void> addNotification(AppNotification notification) async {
    if (userId == null || userId!.isEmpty) return;
    await firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification.toMap());
    await fetchNotifications();
  }
  
  // ... (os métodos abaixo como addSystemNotification e addWithdrawalNotification já chamam addNotification,
  // então eles funcionarão corretamente sem precisar de alterações)

  /// Adiciona notificação de sistema (real)
  Future<void> addSystemNotification({
    required String title,
    required String body,
    AppNotificationType type = AppNotificationType.system,
    Map<String, dynamic>? data,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      title: title,
      body: body,
      date: DateTime.now(),
      type: type,
      data: data,
    );
    await addNotification(notification);
  }

  /// Adiciona notificação de solicitação de saque (real)
  Future<void> addWithdrawalNotification({
    required double requested,
    required double net,
    required double fees,
    String? status,
  }) async {
    final notification = AppNotification(
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
    );
    await addNotification(notification);
  }

  /// Marca todas como lidas no Firestore
  Future<void> markAllAsRead() async {
    if (userId == null || userId!.isEmpty) return;
    final batch = firestore.batch();
    for (final notif in _notifications.where((n) => !n.read)) {
      final docRef = firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notif.id);
      batch.update(docRef, {'read': true});
    }
    await batch.commit();
    await fetchNotifications();
  }

  /// Marca uma notificação como lida no Firestore
  Future<void> markAsRead(String id) async {
    if (userId == null || userId!.isEmpty) return;
    final docRef = firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(id);
    await docRef.update({'read': true});
    await fetchNotifications();
  }

  /// Limpa todas as notificações do Firestore (dev only!)
  Future<void> clearAll() async {
    if (userId == null || userId!.isEmpty) return;
    final collection = firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
    final snapshot = await collection.get();
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _notifications.clear();
    notifyListeners();
  }
}