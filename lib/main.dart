import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase Core e opções do Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// App Check
import 'package:firebase_app_check/firebase_app_check.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wallet_provider.dart';
import 'providers/history_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';

// Telas
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/active_ride_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/history_screen.dart';
import 'screens/terms_of_use_screen.dart';
import 'screens/help_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/notification_screen.dart';

// Notificações locais
import 'services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await LocalNotificationService.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ativando o App Check (use debug para desenvolvimento, playIntegrity para produção)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    // androidProvider: AndroidProvider.playIntegrity, // use isto em produção e no dispositivo físico
  );

  runApp(const LevvaEntregadorApp());
}

class LevvaEntregadorApp extends StatelessWidget {
  const LevvaEntregadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF009688);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) => UserProvider(),
          update: (context, auth, userProvider) {
            final userId = auth.currentDriver?.id;
            if (userId != null && userProvider != null) {
              userProvider.loadUser(userId);
            }
            return userProvider ?? UserProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (context) => WalletProvider(),
          update: (context, auth, previousWallet) {
            final userId = auth.currentDriver?.id;
            if (userId != null && userId.isNotEmpty) {
              previousWallet?.fetchWalletData();
            }
            return previousWallet ?? WalletProvider();
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(userId: null),
          update: (context, auth, previousNotifier) {
            final userId = auth.currentDriver?.id;
            if (previousNotifier == null || previousNotifier.userId != userId) {
              return NotificationProvider(userId: userId);
            }
            return previousNotifier;
          },
        ),
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
        ChangeNotifierProxyProvider<AuthProvider, HistoryProvider>(
          create: (context) => HistoryProvider(userId: null),
          update: (context, auth, previousHistory) {
            final driverId = auth.currentDriver?.id;
            if (previousHistory == null || previousHistory.userId != driverId) {
              return HistoryProvider(userId: driverId);
            }
            return previousHistory;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Levva Entregador',
        theme: ThemeData(
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
          NotificationScreen.routeName: (context) => const NotificationScreen(),
        },
      ),
    );
  }
}