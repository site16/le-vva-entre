// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:levva_entregador/screens/active_ride_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

// ... (suas outras importações)
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/home_status_widgets.dart'; 
import '../widgets/home_action_bar.dart'; 


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

  bool _isNavigatingToActiveRide = false; // <<< ADICIONE ESTA FLAG

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
      Provider.of<WalletProvider>(context, listen: false).fetchWalletData();
      // Provider.of<OrderProvider>(context, listen: false).fetchOrderHistory(); // HistoryProvider já faz isso
    });
  }

  @override
  void dispose() {
    _pulsatingController.dispose();
    super.dispose();
  }

  // ... (seus métodos _buildTopStatusBar, _buildMainContentArea, _buildLoadingOrOrderSection permanecem os mesmos)
  Widget _buildTopStatusBar(BuildContext context, AuthProvider authProvider, OrderProvider orderProvider) {
    bool isOnline = orderProvider.isOnline;
    bool isOnRoute = orderProvider.activeOrder != null;

    String statusText;
    Color statusDisplayColor;
    Color statusBorderColor;
    Color statusBackgroundColor;
    IconData statusIconData;

    if (isOnRoute) {
      statusText = "Em Rota";
      statusDisplayColor = Theme.of(context).colorScheme.secondary;
      statusBorderColor = Theme.of(context).colorScheme.secondary.withOpacity(0.7);
      statusBackgroundColor = Theme.of(context).colorScheme.secondary.withOpacity(0.1);
      statusIconData = Icons.route_rounded; 
    } else if (isOnline) {
      statusText = "Tô on, vamo que vamo";
      statusDisplayColor = Colors.green.shade700;
      statusBorderColor = Colors.green.shade600;
      statusBackgroundColor = Colors.green.withOpacity(0.1);
      statusIconData = Icons.wifi_tethering_rounded;
    } else {
      statusText = "Tô off";
      statusDisplayColor = Colors.grey.shade700;
      statusBorderColor = Colors.grey.shade400;
      statusBackgroundColor = Colors.grey.shade200;
      statusIconData = Icons.portable_wifi_off_rounded;
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8, 
        right: 16, 
        bottom: 8,
      ),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 28),
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
                    border: Border.all(color: statusBorderColor, width: 1.5)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                        child: Icon(
                          statusIconData, 
                          key: ValueKey<String>(statusText), 
                          color: statusDisplayColor, 
                          size: 18, 
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
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tela de notificações (a implementar).')),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainContentArea(BuildContext context, OrderProvider orderProvider) {
    return Container(
      color: Colors.white, 
      child: Center( 
        child: (orderProvider.isOnline && orderProvider.currentOfferedOrder == null && orderProvider.activeOrder == null)
          ? Opacity(
              opacity: 0.1, 
              child: Icon(Icons.explore_outlined, color: Colors.grey[300], size: 120),
            )
          : null, 
      ),
    );
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
        onAccept: () {
          orderProvider.acceptOfferedOrder().then((_) {
            // A navegação para ActiveRideScreen será tratada pelo build() da HomeScreen
            // se _activeOrder for populado.
          });
        },
        onReject: () => orderProvider.rejectOfferedOrder(),
      );
    } else if (orderProvider.activeOrder == null && !orderProvider.isInitializing) { 
      return Container(
        height: 120, 
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        color: Colors.white.withOpacity(0.95), 
        child: Row( 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulsatingAnimation,
              child: Image.asset( 
                'assets/images/levva_icon_transp.png', 
                width: 35, height: 35,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.sync_outlined, 
                  size: 35, 
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "Procurando novos chamados...",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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

    // --- LÓGICA DE CONTROLE DA ANIMAÇÃO PULSANTE ---
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
    // --- FIM DA LÓGICA DE CONTROLE DA ANIMAÇÃO PULSANTE ---

    // --- INÍCIO DA LÓGICA DE NAVEGAÇÃO PARA CORRIDA ATIVA ---
    if (!orderProvider.isInitializing && orderProvider.activeOrder != null && !_isNavigatingToActiveRide) {
      // Define a flag para true ANTES de agendar a navegação
      _isNavigatingToActiveRide = true; 
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // A verificação de ModalRoute.of(context)?.settings.name pode não ser 100% confiável
          // durante transições rápidas. A flag _isNavigatingToActiveRide é mais robusta.
          if (ModalRoute.of(context)?.settings.name != ActiveRideScreen.routeName) {
            if (kDebugMode) {
              print("HomeScreen (build): Pedido ativo detectado (${orderProvider.activeOrder!.id}), navegando para ActiveRideScreen.");
            }
            Navigator.of(context).pushNamed(ActiveRideScreen.routeName).then((_) {
              // Quando ActiveRideScreen é "popada" e voltamos para HomeScreen,
              // resetamos a flag para permitir futuras navegações se necessário.
              if (mounted) {
                setState(() {
                  _isNavigatingToActiveRide = false;
                });
              }
            });
          } else {
            // Já está na tela ou navegação já iniciada, reseta a flag se não for mais necessário
             if (mounted) {
                setState(() {
                  _isNavigatingToActiveRide = false; 
                });
             }
          }
        } else {
          // Se o widget não está montado mas a navegação foi agendada, reseta a flag
           _isNavigatingToActiveRide = false;
        }
      });
    } else if (orderProvider.activeOrder == null && _isNavigatingToActiveRide) {
        // Se o pedido ativo se tornou nulo enquanto estávamos "navegando" (ou a flag ficou true),
        // reseta a flag.
        if (mounted) {
            setState(() {
                 _isNavigatingToActiveRide = false;
            });
        }
    }
    // --- FIM DA LÓGICA DE NAVEGAÇÃO ---

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white, 
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopStatusBar(context, authProvider, orderProvider),
              Expanded(
                child: !orderProvider.isOnline 
                    ? const OfflineScreenContent() 
                    : _buildMainContentArea(context, orderProvider), 
              ),
            ],
          ),
          if (orderProvider.isOnline && (orderProvider.currentOfferedOrder != null || (orderProvider.activeOrder == null && !orderProvider.isInitializing) ))
            Positioned(
              left: 0,
              right: 0,
              bottom: homeActionBarHeightEstimate, 
              child: Material( 
                color: Colors.transparent, 
                child: _buildLoadingOrOrderSection(context, orderProvider, authProvider),
              )
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