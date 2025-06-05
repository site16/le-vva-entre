import 'package:flutter/material.dart';

enum AppNotificationType {
  newOrder,
  coupon,
  info,
  warning,
  system,
  withdrawalRequest, // <-- Adicionado
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final AppNotificationType type;
  final Map<String, dynamic>? data;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.type,
    this.data,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      date: date,
      type: type,
      data: data,
      read: read ?? this.read,
    );
  }

  IconData getIcon() {
    switch (type) {
      case AppNotificationType.newOrder:
        return Icons.local_shipping_rounded;
      case AppNotificationType.coupon:
        return Icons.local_offer_rounded;
      case AppNotificationType.info:
        return Icons.info_outline_rounded;
      case AppNotificationType.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationType.system:
        return Icons.notifications_active_rounded;
      case AppNotificationType.withdrawalRequest:
        return Icons.attach_money_rounded;
    }
  }

  Color getIconColor() {
    switch (type) {
      case AppNotificationType.newOrder:
        return const Color(0xFF009688);
      case AppNotificationType.coupon:
        return const Color(0xFF0088FF);
      case AppNotificationType.info:
        return Colors.blueGrey;
      case AppNotificationType.warning:
        return Colors.orange;
      case AppNotificationType.system:
        return Colors.deepPurple;
      case AppNotificationType.withdrawalRequest:
        return Colors.teal;
    }
  }
}