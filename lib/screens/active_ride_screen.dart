import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:levva_entregador/models/order_model.dart';
import 'package:levva_entregador/providers/order_provider.dart';
import 'package:levva_entregador/widgets/swipe_to_confirm_button.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:levva_entregador/widgets/user_rating_dialog.dart';
import 'package:levva_entregador/widgets/map_display.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class ActiveRideScreen extends StatefulWidget {
  static const routeName = '/active_ride';
  const ActiveRideScreen({super.key});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final _cancelReasonController = TextEditingController();
  Order? _lastKnownActiveOrder;
  bool _isExiting = false;

  static const double _fixedSheetHeight = 0.53;

  @override
  void initState() {
    super.initState();
    _lastKnownActiveOrder = context.read<OrderProvider>().activeOrder;
    _isExiting = false;
    if (kDebugMode) {
      print(
        "ActiveRideScreen initState (widget key: ${widget.key}): _lastKnownActiveOrder=${_lastKnownActiveOrder?.id}",
      );
    }
  }

  @override
  void dispose() {
    _cancelReasonController.dispose();
    if (kDebugMode) {
      print("ActiveRideScreen dispose (widget key: ${widget.key})");
    }
    super.dispose();
  }

  // ---------- Métodos auxiliares e dialogs ----------

  Future<void> _showRideCompletionDialog(
    BuildContext context,
    Order completedOrder,
  ) async {
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final earnings = completedOrder.estimatedValue;

    String paymentMessage = 'O valor foi adicionado à sua carteira LevvaPay.';
    if (completedOrder.paymentMethod == PaymentMethod.cash ||
        completedOrder.paymentMethod == PaymentMethod.cardMachine) {
      paymentMessage =
          'Você já recebeu o valor em ${completedOrder.paymentMethod == PaymentMethod.cash ? 'dinheiro' : 'maquininha'}.';
    }

    if (!mounted) return;
    if (kDebugMode) {
      print(
        "_showRideCompletionDialog (widget key: ${widget.key}): Called for order ${completedOrder.id}.",
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.only(top: 20.0, bottom: 0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/valeu.json',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.green.shade700,
                    size: 40,
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text('Entrega Concluída!', textAlign: TextAlign.center),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Você recebeu: ${currencyFormatter.format(earnings)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(paymentMessage, textAlign: TextAlign.center),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text('Ótimo!'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Exibe a avaliação antes de navegar para a Home!
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (ctx) => UserRatingDialog(
                        userName: completedOrder.customerName ?? "Cliente",
                        onSend: (
                          int rating,
                          List<String> motivos,
                          String comentario,
                          bool bloquear,
                        ) async {
                          // TODO: Envie a avaliação para o backend
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avaliação enviada!')),
                          );
                        },
                      ),
                );
                if (mounted && Navigator.canPop(context)) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelRideDialog(OrderProvider orderProvider) async {
    _cancelReasonController.clear();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Solicitar Cancelamento',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Por que você precisa cancelar esta coleta? Sua resposta será enviada para análise.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _cancelReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo do cancelamento',
                    hintText: 'Ex: O pneu da moto furou.',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: <Widget>[
            TextButton(
              child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Enviar para Análise'),
              onPressed: () async {
                final reason = _cancelReasonController.text.trim();
                Navigator.of(dialogContext).pop();

                if (reason.isNotEmpty) {
                  if (mounted) {
                    await orderProvider.requestCancelActiveOrder(reason);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sua solicitação foi enviada.'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Por favor, descreva o motivo.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _openChat() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade de chat a ser implementada.'),
        ),
      );
    }
  }

  void _openPhone() {
    final Order? activeOrder = context.read<OrderProvider>().activeOrder;
    String? phoneNumber;

    if (activeOrder?.recipientPhoneNumber != null &&
        activeOrder!.recipientPhoneNumber!.isNotEmpty) {
      phoneNumber = activeOrder.recipientPhoneNumber!;
    }

    if (phoneNumber == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de telefone não disponível.')),
        );
      }
      return;
    }

    final Uri phoneUrl = Uri.parse('tel:$phoneNumber');
    launchUrl(phoneUrl);
  }

  void _openMap(String address) async {
    final String query = Uri.encodeComponent(address);
    final Uri googleNavUrl = Uri.parse('google.navigation:q=$query&mode=d');
    final Uri googleSearchUrl = Uri.parse('https://maps.google.com/?q=$query');
    final Uri wazeUrl = Uri.parse('waze://?q=$query&navigate=yes');
    final Uri geoUrl = Uri.parse('geo:0,0?q=$query');

    if (await canLaunchUrl(googleNavUrl)) {
      await launchUrl(googleNavUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(wazeUrl)) {
      await launchUrl(wazeUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(googleSearchUrl)) {
      await launchUrl(googleSearchUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUrl)) {
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir o mapa para $address'),
          ),
        );
      }
    }
  }

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
        return "Desconhecido";
    }
  }

  String _getButtonLabelForStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.toPickup:
        return 'Deslize ao chegar na coleta';
      case OrderStatus.awaitingPickup:
        return 'Deslize para iniciar coleta';
      case OrderStatus.atPickup:
        return 'Deslize para coletar o pedido';
      case OrderStatus.toDeliver:
        return 'Deslize para iniciar a entrega';
      case OrderStatus.atDelivery:
        return 'Deslize para finalizar entrega';
      case OrderStatus.returningToStore:
        return 'Deslize ao chegar na loja';
      case OrderStatus.awaitingStoreConfirmation:
        return 'Aguardando confirmação...';
      case OrderStatus.cancellationRequested:
        return 'Cancelamento em análise';
      default:
        return 'Aguardando...';
    }
  }

  void _handleRideAction(
    OrderProvider provider,
    Order activeOrderSnapshot,
  ) async {
    if (!mounted) return;

    OrderStatus currentStatus = activeOrderSnapshot.status;
    switch (currentStatus) {
      case OrderStatus.toPickup:
        await provider.updateActiveOrderStatus(OrderStatus.awaitingPickup);
        break;
      case OrderStatus.awaitingPickup:
      case OrderStatus.atPickup:
        await provider.updateActiveOrderStatus(OrderStatus.toDeliver);
        break;
      case OrderStatus.toDeliver:
        await provider.updateActiveOrderStatus(OrderStatus.atDelivery);
        break;
      case OrderStatus.atDelivery:
        // PACOTE/OBJETO exige código!
        if (activeOrderSnapshot.type == OrderType.package) {
          await _showPackageCodeDialog(provider, activeOrderSnapshot);
        } else if (activeOrderSnapshot.paymentMethod == PaymentMethod.cash ||
            activeOrderSnapshot.paymentMethod == PaymentMethod.cardMachine) {
          await _showConfirmReceivedDialog(provider, activeOrderSnapshot);
        } else {
          // Pagamento online: finaliza direto
          await provider.updateActiveOrderStatus(OrderStatus.completed);
        }
        break;
      case OrderStatus.returningToStore:
        await provider.updateActiveOrderStatus(
          OrderStatus.awaitingStoreConfirmation,
        );
        break;
      case OrderStatus.awaitingStoreConfirmation:
      case OrderStatus.cancellationRequested:
        return;
      default:
        return;
    }
  }

  Future<void> _showPackageCodeDialog(
    OrderProvider provider,
    Order activeOrder,
  ) async {
    final TextEditingController _codeController = TextEditingController();
    // Use sempre o campo confirmationCode para garantir compatibilidade
    final String? expectedCode = activeOrder.confirmationCode;

    bool success = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmação de Entrega'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para finalizar a entrega, peça ao destinatário os 4 últimos dígitos do telefone dele e digite abaixo:',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Últimos 4 dígitos',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_codeController.text.trim() == (expectedCode ?? '')) {
                    success = true;
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Código incorreto!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (success) {
      // Depois do código correto, segue o fluxo de pagamento normalmente
      if (activeOrder.paymentMethod == PaymentMethod.cash ||
          activeOrder.paymentMethod == PaymentMethod.cardMachine) {
        await _showConfirmReceivedDialog(provider, activeOrder);
      } else {
        await provider.updateActiveOrderStatus(OrderStatus.completed);
      }
    }
  }

  Future<void> _showConfirmReceivedDialog(
    OrderProvider provider,
    Order activeOrder,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Você recebeu o valor?'),
            content: const Text(
              'Confirme se você recebeu o valor do pedido (dinheiro ou maquininha) antes de finalizar a entrega.',
            ),
            actions: [
              TextButton(
                child: const Text('Não'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: const Text('Sim'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    );

    if (result == true) {
      // Finaliza entrega normalmente
      await provider.updateActiveOrderStatus(OrderStatus.completed);
    } else if (result == false) {
      // Mostra orientação para o entregador
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Atenção!'),
                content: const Text(
                  'Não finalize a entrega enquanto não receber o valor. '
                  'Se houver problemas, entre em contato com o suporte.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Entendi'),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
        );
      }
    }
  }

  Widget _buildAwaitingStoreConfirmationUI() {
    return const Column(
      key: ValueKey('awaitingStoreUI'),
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          "Aguardando confirmação da loja...",
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueAccent,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          "Por favor, aguarde o recebimento do dinheiro/maquininha ser validado.",
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWaitingForPickupUI(OrderProvider provider) {
    final minutes = (provider.remainingWaitTime / 60)
        .floor()
        .toString()
        .padLeft(2, '0');
    final seconds = (provider.remainingWaitTime % 60).toString().padLeft(
      2,
      '0',
    );
    return Column(
      key: const ValueKey('waitingUI'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes:$seconds',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color:
                provider.remainingWaitTime < 60
                    ? Colors.red.shade700
                    : Theme.of(context).primaryColorDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Aguardando o cliente/loja...",
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
        if (provider.canCancelAfterWait) ...[
          const SizedBox(height: 10),
          TextButton(
            child: const Text(
              "Cancelar por excesso de espera",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Order? orderToCancel = provider.activeOrder;
              if (orderToCancel != null && mounted) {
                await provider.updateActiveOrderStatus(
                  OrderStatus.cancelledByDriver,
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultETA_UI(Order activeOrder) {
    return Column(
      key: const ValueKey('etaUI'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${activeOrder.estimatedMinutes} min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        '・ ${activeOrder.currentDistance.toStringAsFixed(1)} km',
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 16),
            ),
            Row(
              children: [
                Icon(Icons.circle, color: Colors.teal.shade400, size: 10),
                const SizedBox(width: 6),
                Text(
                  'Chegada prevista ${DateFormat('HH:mm').format(activeOrder.estimatedArrivalTime)}',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final Order? currentActiveOrder = orderProvider.activeOrder;

    if (_isExiting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }

    if (_lastKnownActiveOrder != null && currentActiveOrder == null) {
      if (!_isExiting) {
        _isExiting = true;
        final Order orderThatJustEnded = _lastKnownActiveOrder!;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            if (orderThatJustEnded.status == OrderStatus.completed) {
              await _showRideCompletionDialog(context, orderThatJustEnded);
            } else if (orderThatJustEnded.status.name.toLowerCase().contains(
                  'cancel',
                ) ||
                orderThatJustEnded.status ==
                    OrderStatus.cancellationRequested) {
              if (Navigator.canPop(context)) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            } else {
              if (Navigator.canPop(context)) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          }
        });
      }
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }

    _lastKnownActiveOrder = currentActiveOrder;

    if (currentActiveOrder == null && !_isExiting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
        ),
      );
    }

    if (currentActiveOrder != null && _isExiting) {
      _isExiting = false;
    }

    if (currentActiveOrder == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
        ),
      );
    }

    // ----------- Mapa markers e polylines -----------
    Set<gmaps.Marker> mapMarkers = {};
    Set<gmaps.Polyline> mapPolylines = {};

    // Marcador de coleta (início)
    if (currentActiveOrder.pickupLatitude != null &&
        currentActiveOrder.pickupLongitude != null) {
      mapMarkers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('pickup'),
          position: gmaps.LatLng(
            currentActiveOrder.pickupLatitude!,
            currentActiveOrder.pickupLongitude!,
          ),
          infoWindow: gmaps.InfoWindow(
            title:
                currentActiveOrder.type == OrderType.food
                    ? (currentActiveOrder.storeName ?? "Loja Parceira")
                    : "Remetente",
            snippet: "Coleta",
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Marcador de entrega (destino)
    if (currentActiveOrder.deliveryLatitude != null &&
        currentActiveOrder.deliveryLongitude != null) {
      mapMarkers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('delivery'),
          position: gmaps.LatLng(
            currentActiveOrder.deliveryLatitude!,
            currentActiveOrder.deliveryLongitude!,
          ),
          infoWindow: gmaps.InfoWindow(
            title: currentActiveOrder.customerName ?? "Cliente",
            snippet: "Entrega",
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    // Polyline simples entre coleta e entrega (linha reta)
    if (currentActiveOrder.pickupLatitude != null &&
        currentActiveOrder.pickupLongitude != null &&
        currentActiveOrder.deliveryLatitude != null &&
        currentActiveOrder.deliveryLongitude != null) {
      mapPolylines.add(
        gmaps.Polyline(
          polylineId: const gmaps.PolylineId('route'),
          color: Colors.teal,
          width: 5,
          points: [
            gmaps.LatLng(
              currentActiveOrder.pickupLatitude!,
              currentActiveOrder.pickupLongitude!,
            ),
            gmaps.LatLng(
              currentActiveOrder.deliveryLatitude!,
              currentActiveOrder.deliveryLongitude!,
            ),
          ],
        ),
      );
    }

    // Zoom para inicializar o mapa entre coleta e entrega
    gmaps.CameraPosition? initialCameraPosition;
    if (currentActiveOrder.pickupLatitude != null &&
        currentActiveOrder.pickupLongitude != null) {
      initialCameraPosition = gmaps.CameraPosition(
        target: gmaps.LatLng(
          currentActiveOrder.pickupLatitude!,
          currentActiveOrder.pickupLongitude!,
        ),
        zoom: 14,
      );
    }

    // ----------- FIM DO BLOCO DE MAPA -----------

    return WillPopScope(
      onWillPop: () async {
        final bool isActiveOrderStillPresent =
            context.read<OrderProvider>().activeOrder != null;
        if (isActiveOrderStillPresent && !_isExiting) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Para cancelar, use o botão "X" na tela.'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            currentActiveOrder.type == OrderType.food
                ? (currentActiveOrder.storeName ?? "Pedido de Comida")
                : currentActiveOrder.type == OrderType.package
                ? "Entrega de Pacote"
                : "Corrida de Moto",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (currentActiveOrder.status !=
                    OrderStatus.cancellationRequested &&
                currentActiveOrder.status != OrderStatus.completed &&
                !currentActiveOrder.status.name.toLowerCase().contains(
                  'cancel',
                ))
              IconButton(
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.redAccent,
                ),
                onPressed: () => _showCancelRideDialog(orderProvider),
                tooltip: 'Solicitar Cancelamento',
              ),
          ],
        ),
        body: Stack(
          children: [
            // ----------- MAPA EM BACKGROUND -----------
            Positioned.fill(
              child: MapDisplay(
                initialCameraPosition: initialCameraPosition,
                markers: mapMarkers,
                polylines: mapPolylines,
                enableCurrentLocation: true,
              ),
            ),
            // ----------- FIM MAPA, RESTANTE IGUAL -----------
            DraggableScrollableSheet(
              initialChildSize: _fixedSheetHeight,
              minChildSize: _fixedSheetHeight,
              maxChildSize: _fixedSheetHeight,
              builder: (
                BuildContext sheetContext,
                ScrollController scrollController,
              ) {
                bool isPickupPhase =
                    currentActiveOrder.status == OrderStatus.toPickup ||
                    currentActiveOrder.status == OrderStatus.awaitingPickup ||
                    currentActiveOrder.status == OrderStatus.atPickup;
                String destinationName, role, address;

                if (currentActiveOrder.status == OrderStatus.returningToStore) {
                  address = currentActiveOrder.pickupAddress;
                  role = "Retorno à Loja";
                  destinationName =
                      currentActiveOrder.storeName ?? "Loja Parceira";
                } else if (isPickupPhase) {
                  address = currentActiveOrder.pickupAddress;
                  role =
                      currentActiveOrder.type == OrderType.food
                          ? "Loja"
                          : "Remetente";
                  destinationName =
                      currentActiveOrder.type == OrderType.food
                          ? (currentActiveOrder.storeName ?? 'Loja Parceira')
                          : (currentActiveOrder.customerName ?? 'Cliente');
                } else {
                  address = currentActiveOrder.deliveryAddress;
                  role = "Destinatário";
                  destinationName =
                      currentActiveOrder.customerName ?? 'Cliente';
                }

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (child, animation) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                        child:
                            currentActiveOrder.status ==
                                    OrderStatus.awaitingStoreConfirmation
                                ? _buildAwaitingStoreConfirmationUI()
                                : currentActiveOrder.status ==
                                    OrderStatus.awaitingPickup
                                ? _buildWaitingForPickupUI(orderProvider)
                                : _buildDefaultETA_UI(currentActiveOrder),
                      ),
                      const Divider(height: 30),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destinationName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  role,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: _openChat,
                                tooltip: "Abrir chat",
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone_outlined),
                                onPressed: _openPhone,
                                tooltip: "Ligar",
                              ),
                              IconButton(
                                icon: const Icon(Icons.near_me_outlined),
                                onPressed: () => _openMap(address),
                                tooltip: 'Ir com o mapa',
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                        child: Text(
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getPaymentMethodText(
                                currentActiveOrder.paymentMethod,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (currentActiveOrder.status != OrderStatus.completed &&
                          currentActiveOrder.status !=
                              OrderStatus.cancellationRequested &&
                          !currentActiveOrder.status.name
                              .toLowerCase()
                              .contains('cancel'))
                        SwipeToConfirmButton(
                          key: ValueKey(
                            currentActiveOrder.status.toString() +
                                currentActiveOrder.id,
                          ),
                          text: _getButtonLabelForStatus(
                            currentActiveOrder.status,
                          ),
                          onConfirm:
                              currentActiveOrder.status ==
                                      OrderStatus.awaitingStoreConfirmation
                                  ? () {}
                                  : () => _handleRideAction(
                                    orderProvider,
                                    currentActiveOrder,
                                  ),
                          trackColor:
                              currentActiveOrder.status ==
                                      OrderStatus.awaitingStoreConfirmation
                                  ? Colors.grey.shade400
                                  : Theme.of(context).primaryColor,
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
