import 'package:flutter/material.dart';
import '../models/ride_history_entry.dart';
import '../models/order_model.dart';

class HistorySummarySheet extends StatelessWidget {
  final RideHistoryEntry entry;
  const HistorySummarySheet({super.key, required this.entry});

  static const Color accentColor = Color(0xFF009688);
  static const Color iconColor = Color(0xFF4C446A); // Roxo elegante para os ícones do status
  static const Color timeColor = accentColor; // Turquesa, igual ao resto da UI

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.online:
        return "Pagamento Online (LevvaPay)";
      case PaymentMethod.cash:
        return "Dinheiro";
      case PaymentMethod.cardMachine:
        return "Maquininha de Cartão";
      case PaymentMethod.levvaPay:
        return "LevvaPay (Online)";
      case PaymentMethod.card:
        return "Cartão";
      default:
        return "Não informado";
    }
  }

  Widget _middleDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Container(
          width: 30,
          height: 1,
          color: Colors.grey[300],
        ),
      );

  Widget _statusColumn(IconData icon, String time) => Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 6),
          Text(
            time,
            style: const TextStyle(
              color: timeColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          )
        ],
      );

  Widget _buildStatusRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      margin: const EdgeInsets.only(top: 12, bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _statusColumn(Icons.bookmark_border, entry.timeStart ?? '--:--'),
          _middleDivider(),
          _statusColumn(Icons.remove_red_eye_outlined, entry.timeAccepted ?? '--:--'),
          _middleDivider(),
          _statusColumn(Icons.directions_bike, entry.timeDelivered ?? '--:--'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = entry.dateTime;
    final String dateStr = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString()}';
    final String orderCode = entry.code ?? "#00000000";
    final String paymentValue = "R\$ ${entry.value.toStringAsFixed(2).replaceAll('.', ',')}";
    final String user = entry.userName ?? "@usuário";
    final String paymentType = _getPaymentMethodText(entry.paymentMethod);
    final String detail = entry.typeName;
    final String endereco = entry.destination;
    final String status = entry.statusName;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo: "Essa corrida foi assim", data e código
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Essa corrida foi assim.",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                  ),
                ),
                Card(
                  color: accentColor.withOpacity(0.07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status centralizado
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: accentColor.withOpacity(0.15),
                    radius: 32,
                    child: Icon(entry.iconData, size: 38, color: accentColor),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: accentColor, size: 12),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: const TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Linha de status igual a imagem fornecida
            _buildStatusRow(),
            Divider(color: Colors.grey.shade300, thickness: 1.5, indent: 80, endIndent: 80),
            const SizedBox(height: 8),
            // Detalhes
            Row(
              children: [
                const Text(
                  "Detalhes:",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    detail,
                    style: const TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: Colors.grey[300], thickness: 1.2),
            const SizedBox(height: 10),
            // Valor e Entrega
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Valor Recebido",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: accentColor, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            paymentValue,
                            style: const TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 38,
                  child: VerticalDivider(
                    color: Colors.grey[300],
                    thickness: 1.3,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.place, color: accentColor, size: 18),
                          const SizedBox(width: 5),
                          Text(
                            "Entrega",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        endereco,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15.5,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.grey[300], thickness: 1.2),
            const SizedBox(height: 12),
            // Pagamento
            const Text(
              "Pagamento",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: accentColor, size: 20),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      paymentType,
                      style: const TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300], thickness: 1.2),
            const SizedBox(height: 10),
            // Usuário
            const Text(
              "Informações do usuário",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(Icons.person, color: accentColor, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    user,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      color: accentColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.notes!,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}