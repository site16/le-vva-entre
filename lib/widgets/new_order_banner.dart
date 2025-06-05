import 'package:flutter/material.dart';
import 'package:levva_entregador/models/order_model.dart';

class NewOrderBanner extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  const NewOrderBanner({
    Key? key,
    required this.order,
    this.onTap,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simula horário (você pode passar como parâmetro depois)
    final now = TimeOfDay.now();
    String hour = now.hourOfPeriod.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    String ampm = now.period == DayPeriod.am ? 'AM' : 'PM';

    // Altura do AppBar padrão
    const double appBarHeight = kToolbarHeight; // 56.0

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: appBarHeight + 12), // Desce abaixo do appbar
          width: MediaQuery.of(context).size.width * 0.65,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.09),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Novo pedido!',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color.fromARGB(221, 255, 255, 255),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Pedido para ${order.pickupAddress}",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 12.7,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$hour:$minute $ampm",
                style: TextStyle(
                  color: const Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFFFFFFFF), size: 20),
                  onPressed: onClose,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}