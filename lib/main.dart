// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Importações dos Providers
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/history_provider.dart'; 

// Importações das Telas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/active_ride_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/history_screen.dart';
import 'screens/terms_of_use_screen.dart';
import 'screens/help_screen.dart';
import 'screens/sos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null); 
  runApp(const LevvaEntregadorApp());
}

class LevvaEntregadorApp extends StatelessWidget {
  const LevvaEntregadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF009688);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, WalletProvider, OrderProvider>(
          create: (context) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final wallet = Provider.of<WalletProvider>(context, listen: false);
            return OrderProvider(auth, wallet);
          },
          update: (context, auth, wallet, previousOrderProvider) {
            final newProvider = OrderProvider(auth, wallet);
            newProvider.rehydratePreviousState(previousOrderProvider);
            return newProvider;
          },
        ),
        ChangeNotifierProxyProvider<OrderProvider, HistoryProvider>(
          create: (context) {
            final orderProvider = Provider.of<OrderProvider>(context, listen: false);
            return HistoryProvider(orderProvider);
          },
          update: (context, orderProvider, previousHistoryProvider) {
            // REUTILIZA a instância de previousHistoryProvider e atualiza sua dependência
            if (previousHistoryProvider == null) {
              // Isso não deve acontecer se 'create' foi chamado corretamente, mas é uma salvaguarda.
              final initialOrderProvider = Provider.of<OrderProvider>(context, listen: false);
              return HistoryProvider(initialOrderProvider);
            }
            previousHistoryProvider.updateOrderProvider(orderProvider);
            return previousHistoryProvider; // Retorna a mesma instância atualizada
          },
          // O dispose do HistoryProvider será chamado automaticamente pelo Provider
          // quando o próprio HistoryProvider for removido da árvore de widgets.
          // O dispose do HistoryProvider (que remove o listener do _orderProvider) é suficiente.
        ),
      ],
      child: MaterialApp(
        title: 'Levva Entregador',
        theme: ThemeData( // Seu ThemeData aqui
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,
            primary: primaryColor,
            onPrimary: Colors.white,
            secondary: Colors.amber,
            onSecondary: Colors.black,
            surface: Colors.white,
            onSurface: Colors.black,
            background: Colors.white,
            onBackground: Colors.black,
            error: Colors.redAccent,
            onError: Colors.white,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 2,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            hintStyle: TextStyle(color: Colors.grey[500]),
            labelStyle: TextStyle(color: Colors.grey[700]),
            prefixIconColor: Colors.grey[600],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 15.0,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            color: Colors.white,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 4,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primaryColor),
          ),
          iconTheme: IconThemeData(
            color: Colors.grey[800],
          ),
          primaryColor: primaryColor,
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'), 
        ],
        locale: const Locale('pt', 'BR'), 
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          ActiveRideScreen.routeName: (context) => const ActiveRideScreen(),
          ProfileScreen.routeName: (context) => const ProfileScreen(),
          WalletScreen.routeName: (context) => const WalletScreen(),
          HistoryScreen.routeName: (context) => const HistoryScreen(),
          TermsOfUseScreen.routeName: (context) => const TermsOfUseScreen(),
          HelpScreen.routeName: (context) => const HelpScreen(),
          SosScreen.routeName: (context) => const SosScreen(),
        },
      ),
    );
  }
}