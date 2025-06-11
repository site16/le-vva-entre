import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashOrRootScreen extends StatefulWidget {
  const SplashOrRootScreen({super.key});

  @override
  State<SplashOrRootScreen> createState() => _SplashOrRootScreenState();
}

class _SplashOrRootScreenState extends State<SplashOrRootScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF009688),
        body: Center(
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Image.asset(
              'assets/images/levva_icon_transp_branco.png',
              height: 88,
              width: 88,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (authProvider.isAuthenticated) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}