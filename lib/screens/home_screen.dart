import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:levva_entregador/models/app_notification.dart';
import 'package:levva_entregador/models/order_model.dart';
import 'package:levva_entregador/screens/active_ride_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/home_status_widgets.dart';
import '../widgets/home_action_bar.dart';
import '../widgets/new_order_banner.dart';
import '../widgets/map_display.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pulsatingController;
  late Animation<double> _pulsatingAnimation;
  final double homeActionBarHeightEstimate = 85.0;

  bool _isNavigatingToActiveRide = false;
  Order? _lastOfferedOrder;
  bool _showBanner = false;

  Timer? _bannerTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _pulsatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulsatingAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulsatingController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.currentDriver?.id;
      if (userId != null && userId.isNotEmpty) {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        walletProvider.fetchWalletData();
      }
    });
  }

  @override
  void dispose() {
    _pulsatingController.dispose();
    _bannerTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notificação.mp3'), volume: 1.0);
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao tocar som de notificação: $e");
      }
    }
  }

  Future<void> _stopNotificationSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      if (kDebugMode) {
        print("Erro ao parar som de notificação: $e");
      }
    }
  }

  void _showNewOrderBanner(Order order) {
    setState(() {
      _showBanner = true;
      _lastOfferedOrder = order;
    });
    _playNotificationSound();
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
        _stopNotificationSound();
      }
    });
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    setState(() {
      _showBanner = false;
    });
    _stopNotificationSound();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orderProvider = Provider.of<OrderProvider>(context);
    final offeredOrder = orderProvider.currentOfferedOrder;

    if (offeredOrder != null && offeredOrder != _lastOfferedOrder) {
      _showNewOrderBanner(offeredOrder);

      Provider.of<NotificationProvider>(context, listen: false).addSystemNotification(
        title: 'Novo pedido recebido!',
        body: 'Você tem um novo pedido para aceitar.',
        type: AppNotificationType.newOrder,
      );
    } else if (offeredOrder == null && _showBanner) {
      _dismissBanner();
    }
  }

  Widget _buildTopStatusBar(BuildContext context, AuthProvider authProvider, OrderProvider orderProvider) {
    bool isOnline = orderProvider.isOnline;
    bool isOnRoute = orderProvider.activeOrder != null;

    String statusText;
    Color statusDisplayColor;
    Color statusBorderColor;
    Color statusBackgroundColor;

    if (isOnRoute) {
      statusText = "Em Rota";
      statusDisplayColor = Theme.of(context).colorScheme.secondary;
      statusBorderColor = Theme.of(context).colorScheme.secondary.withOpacity(0.7);
      statusBackgroundColor = Theme.of(context).colorScheme.secondary.withOpacity(0.1);
    } else if (isOnline) {
      statusText = "Disponível";
      statusDisplayColor = const Color(0xFFFFFFFF);
      statusBorderColor = const Color(0xFF43A047);
      statusBackgroundColor = const Color(0xFF43A047);
    } else {
      statusText = "Indisponível";
      statusDisplayColor = Colors.grey.shade700;
      statusBorderColor = Colors.grey.shade400;
      statusBackgroundColor = Colors.grey.shade200;
    }

    final unreadCount = Provider.of<NotificationProvider>(context).unreadCount;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 16,
        bottom: 8,
      ),
      color: Colors.transparent,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: isOnRoute ? null : () => orderProvider.toggleOnlineStatus(!isOnline),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: statusBackgroundColor,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: statusBorderColor, width: 1.5)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                        child: isOnline && !isOnRoute
                            ? AnimatedBuilder(
                                animation: _pulsatingController,
                                builder: (context, child) => Transform.scale(
                                  scale: _pulsatingAnimation.value,
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    child: Image.asset(
                                      'assets/images/levva_icon_transp.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                  ),
                                ),
                              )
                            : isOnRoute
                                ? Icon(
                                    Icons.route_rounded,
                                    key: ValueKey<String>(statusText),
                                    color: statusDisplayColor,
                                    size: 18,
                                  )
                                : Image.asset(
                                    'assets/images/levva_icon_transp.png',
                                    key: ValueKey<String>(statusText),
                                    width: 24,
                                    height: 24,
                                    color: Colors.grey.shade700,
                                  ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusDisplayColor,
                          fontWeight: FontWeight.bold, fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                if (unreadCount > 0)
                  Positioned(
                    right: 0, top: 2,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.transparent, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen())
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentArea(BuildContext context, OrderProvider orderProvider) {
    return const SizedBox.shrink();
  }

  Widget _buildLoadingOrOrderSection(BuildContext context, OrderProvider orderProvider, AuthProvider authProvider) {
    if (!orderProvider.isOnline) {
      return const SizedBox.shrink();
    }

    if (orderProvider.currentOfferedOrder != null) {
      return NewOrderOfferPanel(
        order: orderProvider.currentOfferedOrder!,
        initialTimeToAccept: 90,
        currentTimeToAccept: orderProvider.timeToAcceptOrder,
        driverVehicleType: authProvider.currentDriver?.vehicleType,
        onAccept: () async {
          _stopNotificationSound();
          await orderProvider.acceptOfferedOrder();
        },
        onReject: () async {
          _stopNotificationSound();
          await orderProvider.rejectOfferedOrder();
        },
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    if (!authProvider.isAuthenticated || authProvider.currentDriver == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool shouldPulsate = orderProvider.isOnline &&
        orderProvider.activeOrder == null &&
        orderProvider.currentOfferedOrder == null &&
        !orderProvider.isInitializing;

    if (shouldPulsate) {
      if (!_pulsatingController.isAnimating) {
        _pulsatingController.repeat(reverse: true);
      }
    } else {
      if (_pulsatingController.isAnimating) {
        _pulsatingController.stop();
      }
    }

    if (!orderProvider.isInitializing && orderProvider.activeOrder != null && !_isNavigatingToActiveRide) {
      _isNavigatingToActiveRide = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (ModalRoute.of(context)?.settings.name != ActiveRideScreen.routeName) {
            if (kDebugMode) {
              print("HomeScreen (build): Pedido ativo detectado (${orderProvider.activeOrder!.id}), navegando para ActiveRideScreen.");
            }
            Navigator.of(context).pushNamed(ActiveRideScreen.routeName).then((_) {
              if (mounted) {
                setState(() {
                  _isNavigatingToActiveRide = false;
                });
              }
            });
          } else {
            if (mounted) {
              setState(() {
                _isNavigatingToActiveRide = false;
              });
            }
          }
        } else {
          _isNavigatingToActiveRide = false;
        }
      });
    } else if (orderProvider.activeOrder == null && _isNavigatingToActiveRide) {
      if (mounted) {
        setState(() {
          _isNavigatingToActiveRide = false;
        });
      }
    }

    final offeredOrder = orderProvider.currentOfferedOrder;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: MapDisplay(
              enableCurrentLocation: true,
              initialCameraPosition: CameraPosition(
                target: LatLng(-23.5505, -46.6333),
                zoom: 13,
              ),
            ),
          ),
          Column(
            children: [
              _buildTopStatusBar(context, authProvider, orderProvider),
              Expanded(
                child: orderProvider.isOnline
                    ? _buildMainContentArea(context, orderProvider)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          AnimatedSlide(
            offset: (_showBanner && offeredOrder != null) ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: (_showBanner && offeredOrder != null)
                ? NewOrderBanner(
                    order: offeredOrder,
                    onTap: () {},
                    onClose: _dismissBanner,
                  )
                : const SizedBox.shrink(),
          ),
          if (orderProvider.isOnline && (orderProvider.currentOfferedOrder != null || (orderProvider.activeOrder == null && !orderProvider.isInitializing)))
            Positioned(
              left: 0,
              right: 0,
              bottom: homeActionBarHeightEstimate,
              child: Material(
                color: Colors.transparent,
                child: _buildLoadingOrOrderSection(context, orderProvider, authProvider),
              ),
            ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              bottom: true,
              top: false,
              child: HomeActionBar(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
    );
  }
}