// TODO Implement this library.
// lib/screens/sos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para SystemUiOverlayStyle
import 'package:url_launcher/url_launcher.dart';

class EmergencyContact {
  final String name;
  final String number;
  final String description;
  final IconData icon;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
  });
}

class SosScreen extends StatelessWidget {
  static const routeName = '/sos'; // Nome da rota para navegação
  const SosScreen({super.key});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Usar 'mounted' diretamente no context do ScaffoldMessenger é uma forma válida.
      // Ou, se fosse um StatefulWidget, if (this.mounted)
      if (scaffoldMessenger.mounted) { 
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Não foi possível realizar a ligação para $phoneNumber'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmergencyContactCard(BuildContext context, EmergencyContact contact) {
    Color iconCircleAvatarColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    Color iconColor = Theme.of(context).colorScheme.primary;

    if (contact.name == "Polícia Militar") {
      iconCircleAvatarColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade700;
    } else if (contact.name == "SAMU (Ambulância)") {
      iconCircleAvatarColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
    } else if (contact.name == "Corpo de Bombeiros") {
      iconCircleAvatarColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade800;
    } else if (contact.name == "Defesa Civil") {
      iconCircleAvatarColor = Colors.green.shade50;
      iconColor = Colors.green.shade700;
    } else if (contact.name == "Central de Atendimento à Mulher") {
      iconCircleAvatarColor = Colors.purple.shade50;
      iconColor = Colors.purple.shade700;
    } else if (contact.name == "Suporte de Emergência Levva") {
      iconCircleAvatarColor = Theme.of(context).colorScheme.primary.withOpacity(0.08);
      iconColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _makePhoneCall(context, contact.number),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: iconCircleAvatarColor,
                child: Icon(contact.icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      contact.description,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    contact.number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "LIGAR",
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<EmergencyContact> emergencyContacts = [
      EmergencyContact(name: "Polícia Militar", number: "190", description: "Para emergências policiais e segurança pública.", icon: Icons.local_police_rounded),
      EmergencyContact(name: "SAMU (Ambulância)", number: "192", description: "Para emergências médicas e atendimento pré-hospitalar.", icon: Icons.medical_services_rounded),
      EmergencyContact(name: "Corpo de Bombeiros", number: "193", description: "Para incêndios, resgates e salvamentos.", icon: Icons.local_fire_department_rounded),
      EmergencyContact(name: "Defesa Civil", number: "199", description: "Para desastres naturais, enchentes e deslizamentos.", icon: Icons.shield_rounded),
      EmergencyContact(name: "Central de Atendimento à Mulher", number: "180", description: "Para denúncias e apoio em casos de violência contra a mulher.", icon: Icons.support_agent_rounded),
      EmergencyContact(name: "Suporte de Emergência Levva", number: "08000000000", description: "Problemas urgentes com sua corrida ou entrega Levva.", icon: Icons.support_rounded),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey.shade800, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'SOS - Emergência',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, 
        elevation: 0.5,
        scrolledUnderElevation: 1.0,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
            child: Text(
              'Precisa de ajuda imediata?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: emergencyContacts.length,
              itemBuilder: (context, index) {
                return _buildEmergencyContactCard(context, emergencyContacts[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, MediaQuery.of(context).padding.bottom + 16.0),
            color: Colors.amber.shade100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Atenção: Use estes números apenas em caso de emergência real. O uso indevido pode ter consequências.',
                    style: TextStyle(color: Colors.amber.shade900, fontSize: 14, fontWeight: FontWeight.normal),
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