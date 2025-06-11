import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/vehicle_type_enum.dart';
import '../widgets/map_display.dart'; // Importa o MapDisplay
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Exibe apenas o mapa (no estado offline)
class OfflineScreenContent extends StatelessWidget {
  final String deliverymanId;
  const OfflineScreenContent({super.key, required this.deliverymanId});

  @override
  Widget build(BuildContext context) {
    // Exibe o mapa em vez do layout offline antigo
    return MapDisplay(
      enableCurrentLocation: true,
      deliverymanId: deliverymanId,
      initialCameraPosition: const CameraPosition(
        target: LatLng(-23.5505, -46.6333), // Exemplo: São Paulo
        zoom: 13,
      ),
    );
  }
}

class NewOrderOfferPanel extends StatefulWidget {
  final Order order;
  final int initialTimeToAccept;
  final VehicleType? driverVehicleType;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final int currentTimeToAccept;

  const NewOrderOfferPanel({
    super.key,
    required this.order,
    required this.initialTimeToAccept,
    required this.driverVehicleType,
    required this.onAccept,
    required this.onReject,
    required this.currentTimeToAccept,
  });

  @override
  State<NewOrderOfferPanel> createState() => _NewOrderOfferPanelState();
}

class _NewOrderOfferPanelState extends State<NewOrderOfferPanel> {
  double _dragPosition = 0.0; // Offset horizontal do botão a partir do centro
  double _dragExtentRatio = 0.0;

  bool _isConfirmingAction = false;
  bool _actionWasAccept = false;
  Timer? _feedbackDisplayTimer;

  @override
  void dispose() {
    _feedbackDisplayTimer?.cancel();
    super.dispose();
  }

  void _handleAction(bool accepted) {
    if (!mounted || _isConfirmingAction) return;
    setState(() {
      _isConfirmingAction = true;
      _actionWasAccept = accepted;
    });
    _feedbackDisplayTimer?.cancel();
    _feedbackDisplayTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        if (accepted)
          widget.onAccept();
        else
          widget.onReject();
      }
    });
  }

  String _getOrderTypeName(OrderType type) {
    switch (type) {
      case OrderType.moto:
        return 'Passageiro';
      case OrderType.package:
        return 'Entrega';
      case OrderType.food:
        return 'Delivery';
      default:
        return type.name.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData vehicleIconForSwipeButton = Icons.two_wheeler_outlined;
    if (widget.driverVehicleType == VehicleType.moto)
      vehicleIconForSwipeButton = Icons.motorcycle_outlined;
    if (widget.driverVehicleType == VehicleType.bike)
      vehicleIconForSwipeButton = Icons.directions_bike_outlined;

    String orderTitle = _getOrderTypeName(widget.order.type);
    String locationHint =
        widget.order.storeName ?? widget.order.pickupAddress.split(',').first;
    if (locationHint.length > 25)
      locationHint = "${locationHint.substring(0, 22)}...";
    orderTitle += " - $locationHint";

    double screenWidth = MediaQuery.of(context).size.width;
    double dragButtonSize = 60.0;
    double trackHeight = 70.0;
    double trackHorizontalMargin = 16.0;

    double maxDrag =
        (screenWidth / 2) -
        trackHorizontalMargin -
        (dragButtonSize / 2) -
        20; // 20 de margem extra
    double actionThreshold = maxDrag * 0.5; // 50% do caminho para confirmar

    Color leftTrackDragColor = Colors.red.withOpacity(
      (_dragExtentRatio < 0 ? -_dragExtentRatio : 0) * 0.6,
    );
    Color rightTrackDragColor = Colors.green.withOpacity(
      (_dragExtentRatio > 0 ? _dragExtentRatio : 0) * 0.6,
    );

    Color trackConfirmationColor = Colors.grey[200]!;
    if (_isConfirmingAction) {
      trackConfirmationColor =
          _actionWasAccept ? Colors.green.shade600 : Colors.red.shade600;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card de Informações (sem alterações)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orderTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Oferta exclusiva para você",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "R\$ ${widget.order.estimatedValue.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.driverVehicleType?.name.toUpperCase() ?? "VEÍCULO",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    "${widget.order.routeDistance.toStringAsFixed(1)} km",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Barra de Ação Deslizante
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: trackHeight,
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: trackHorizontalMargin,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: trackConfirmationColor,
            borderRadius: BorderRadius.circular(trackHeight / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IgnorePointer(
            ignoring: _isConfirmingAction,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!_isConfirmingAction)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                      child: Row(
                        children: [
                          Expanded(child: Container(color: leftTrackDragColor)),
                          Expanded(
                            child: Container(color: rightTrackDragColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Align(
                  alignment: Alignment(-0.85, 0),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.black54,
                    size: 28,
                  ),
                ),
                const Align(
                  alignment: Alignment(0.85, 0),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                // Botão deslizante central
                Transform.translate(
                  offset: Offset(_dragPosition, 0),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (_isConfirmingAction) return;
                      setState(() {
                        _dragPosition += details.delta.dx;
                        _dragPosition = _dragPosition.clamp(-maxDrag, maxDrag);

                        _dragExtentRatio = (_dragPosition / maxDrag).clamp(
                          -1.0,
                          1.0,
                        );
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_isConfirmingAction) return;
                      if (_dragPosition > actionThreshold) {
                        _handleAction(true);
                        setState(() => _dragPosition = maxDrag);
                      } else if (_dragPosition < -actionThreshold) {
                        _handleAction(false);
                        setState(() => _dragPosition = -maxDrag);
                      } else {
                        setState(() => _dragPosition = 0.0);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: dragButtonSize,
                      height: dragButtonSize,
                      decoration: BoxDecoration(
                        color:
                            _isConfirmingAction
                                ? (_actionWasAccept
                                    ? Colors.green.shade700
                                    : Colors.red.shade700)
                                : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _isConfirmingAction
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.grey.shade300,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!_isConfirmingAction)
                            SizedBox(
                              width: dragButtonSize,
                              height: dragButtonSize,
                              child: CircularProgressIndicator(
                                value: (widget.currentTimeToAccept /
                                        widget.initialTimeToAccept.toDouble())
                                    .clamp(0.0, 1.0),
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.currentTimeToAccept <= 15
                                      ? Colors.red.shade500
                                      : Colors.green.shade600,
                                ),
                                backgroundColor: Colors.grey.shade300
                                    .withOpacity(0.5),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            child:
                                _isConfirmingAction
                                    ? Icon(
                                      _actionWasAccept
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.highlight_off_rounded,
                                      color: Colors.white,
                                      size: dragButtonSize * 0.5,
                                    )
                                    : Image.asset(
                                      'assets/images/levva_icon_transp.png',
                                      width: dragButtonSize * 0.5,
                                      height: dragButtonSize * 0.5,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Icon(
                                          vehicleIconForSwipeButton,
                                          color: Colors.black,
                                          size: dragButtonSize * 0.45,
                                        );
                                      },
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}