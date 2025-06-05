// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart'; // Usado para o logout

// Importe as telas para navegação
import '../screens/wallet_screen.dart';
import '../screens/history_screen.dart';
import '../screens/help_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../screens/sos_screen.dart'; // Importação da tela SOS

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildDrawerHeader(BuildContext context, AuthProvider authProvider) {
    final driver = authProvider.currentDriver;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 25.0,
        bottom: 25.0,
        left: 20.0,
        right: 20.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withOpacity(0.9),
            backgroundImage: driver?.profileImageUrl != null && driver!.profileImageUrl!.isNotEmpty
                ? NetworkImage(driver.profileImageUrl!)
                : null,
            child: driver?.profileImageUrl == null || driver!.profileImageUrl!.isEmpty
                ? Icon(Icons.person_rounded, size: 40, color: primaryColor.withOpacity(0.9))
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            driver?.name ?? 'Motorista Levva',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (driver?.email != null)
            Text(
              driver!.email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    final Color selectedColor = const Color(0xFF009688); 
    final Color defaultColor = Colors.grey.shade800;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
      leading: Icon(
        icon,
        color: iconColor ?? (isSelected ? selectedColor : defaultColor),
        size: 24,
      ),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? (isSelected ? selectedColor : defaultColor),
          fontSize: 15.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      tileColor: isSelected ? selectedColor.withOpacity(0.08) : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // O MÉTODO _showSOSDialog FOI REMOVIDO, pois o botão SOS agora navega para a tela.

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Column(
        children: <Widget>[
          _buildDrawerHeader(context, authProvider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              children: <Widget>[
                
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  text: 'LevvaPay (Carteira)',
                  isSelected: currentRoute == WalletScreen.routeName,
                  onTap: () {
                     Navigator.of(context).pop();
                     if (currentRoute != WalletScreen.routeName) {
                        Navigator.of(context).pushNamed(WalletScreen.routeName);
                     }
                  },
                ),
                
                _buildDrawerItem(
                  icon: Icons.history_rounded,
                  text: 'Histórico de Corridas', // Alterado de "Chamados" para "Corridas"
                  isSelected: currentRoute == HistoryScreen.routeName,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (currentRoute != HistoryScreen.routeName) {
                      Navigator.of(context).pushNamed(HistoryScreen.routeName);
                    }
                  },
                ),
                const SizedBox(height: 10),
                const Divider(indent: 20, endIndent: 20, height: 1, thickness: 0.5),
                const SizedBox(height: 10),
                _buildDrawerItem(
                  icon: Icons.description_rounded,
                  text: 'Termos de Uso',
                  isSelected: currentRoute == TermsOfUseScreen.routeName,
                  onTap: () {
                    Navigator.of(context).pop();
                     if (currentRoute != TermsOfUseScreen.routeName) {
                        Navigator.of(context).pushNamed(TermsOfUseScreen.routeName);
                     }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help_center_rounded,
                  text: 'Ajuda & Suporte',
                  isSelected: currentRoute == HelpScreen.routeName,
                  onTap: () {
                    Navigator.of(context).pop();
                     if (currentRoute != HelpScreen.routeName) {
                        Navigator.of(context).pushNamed(HelpScreen.routeName);
                     }
                  },
                ),
                // O item de lista "SOS Emergência" foi removido daqui
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: EdgeInsets.only(
              left: 16.0, 
              right: 16.0, 
              bottom: MediaQuery.of(context).padding.bottom + 20.0, 
              top: 15.0
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.warning_amber, size: 20),
                    label: const Text('SOS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Fecha o drawer
                      // NAVEGA PARA A TELA SOS EM VEZ DE MOSTRAR UM DIÁLOGO
                      Navigator.of(context).pushNamed(SosScreen.routeName); 
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                    label: const Text('Sair', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      orderProvider.toggleOnlineStatus(false, forceUpdate: true);
                      authProvider.logout();
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}