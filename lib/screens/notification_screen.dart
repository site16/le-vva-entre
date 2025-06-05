import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  static const routeName = '/notifications';

  const NotificationScreen({super.key});

  void _showDetailSheet(BuildContext context, AppNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(99),
                  ),
                  margin: const EdgeInsets.only(bottom: 18),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        notification.getIconColor().withOpacity(0.12),
                    child: Icon(
                      notification.getIcon(),
                      color: notification.getIconColor(),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                notification.body,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              if (notification.type == AppNotificationType.withdrawalRequest &&
                  notification.data != null) ...[
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'Detalhes do Saque',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                _buildDetailRow(
                  'Valor solicitado:',
                  notification.data?['requested'] ?? '',
                ),
                _buildDetailRow(
                  'Taxas:',
                  notification.data?['fees'] ?? '',
                ),
                _buildDetailRow(
                  'Valor líquido:',
                  notification.data?['net'] ?? '',
                ),
                if (notification.data?['status'] != null)
                  _buildDetailRow(
                    'Status:',
                    notification.data?['status'],
                  ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd/MM/yy • HH:mm', 'pt_BR')
                        .format(notification.date),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF009688),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificationProvider>(context);
    final notifications = notifProvider.notifications;
    final Color mainColor = const Color(0xFF009688);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Notificações',
          style: TextStyle(color: Colors.black),
        ),
        elevation: 1,
        centerTitle: true,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Color(0xFF009688)),
              tooltip: 'Marcar todas como lidas',
              onPressed: notifProvider.markAllAsRead,
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Limpar todas',
              onPressed: () async {
                final confirm = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar notificações?'),
                    content: const Text('Deseja apagar TODAS as notificações?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Limpar Tudo', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  notifProvider.clearAll();
                }
              },
            ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded,
                      color: Colors.grey.shade300, size: 70),
                  const SizedBox(height: 20),
                  Text(
                    'Nenhuma notificação encontrada',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                        fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: notifications.length,
              separatorBuilder: (c, i) => Divider(
                height: 1,
                color: Colors.grey.shade100,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return ListTile(
                  onTap: () {
                    notifProvider.markAsRead(n.id);
                    if (n.type == AppNotificationType.withdrawalRequest) {
                      _showDetailSheet(context, n);
                    }
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: n.getIconColor().withOpacity(0.12),
                        child: Icon(n.getIcon(), color: n.getIconColor(), size: 28),
                      ),
                      if (!n.read)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: mainColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: n.read ? FontWeight.w400 : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    n.body,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('dd/MM/yy\nHH:mm', 'pt_BR').format(n.date),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      if (n.type == AppNotificationType.withdrawalRequest)
                        IconButton(
                          icon: const Icon(Icons.info_outline_rounded,
                              color: Color(0xFF009688), size: 22),
                          tooltip: 'Detalhes do saque',
                          onPressed: () {
                            notifProvider.markAsRead(n.id);
                            _showDetailSheet(context, n);
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}