import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AppNotificationType {
  newOrder,
  coupon,
  info,
  warning,
  system,
  withdrawalRequest,
}

AppNotificationType appNotificationTypeFromString(String value) {
  switch (value) {
    case 'newOrder':
      return AppNotificationType.newOrder;
    case 'coupon':
      return AppNotificationType.coupon;
    case 'info':
      return AppNotificationType.info;
    case 'warning':
      return AppNotificationType.warning;
    case 'system':
      return AppNotificationType.system;
    case 'withdrawalRequest':
      return AppNotificationType.withdrawalRequest;
    default:
      return AppNotificationType.system;
  }
}

String appNotificationTypeToString(AppNotificationType type) {
  return type.toString().split('.').last;
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

  // --- Firestore Serialization ---
  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'] as String,
      body: map['body'] as String,
      date: (map['date'] as Timestamp?)?.toDate() ??
          DateTime.tryParse(map['date'] ?? '') ??
          DateTime.now(),
      type: map['type'] is String
          ? appNotificationTypeFromString(map['type'])
          : AppNotificationType.system,
      data: map['data'] as Map<String, dynamic>?,
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': date,
      'type': appNotificationTypeToString(type),
      'data': data,
      'read': read,
    };
  }
}