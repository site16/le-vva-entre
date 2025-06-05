// lib/screens/profile_screen.dart
// Exibe as informações do perfil do entregador, como nome, email,
// dados do veículo e documentos. Permite a edição (simulada).
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) { // O 'context' principal do método build
    // Dados mocados do perfil
    const String driverName = "Carlos Silva";
    const String driverEmail = "carlos.silva@email.com";
    const String driverPhone = "(31) 99999-8888";
    const String vehicleModel = "Honda CG 160 Titan";
    const String licensePlate = "XYZ-1234";
    const String driverRating = "4.85"; // Exemplo de avaliação

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar( // Removido o 'const' daqui
                        radius: 60,
                        // backgroundImage: NetworkImage('URL_DA_FOTO_DO_PERFIL'), // Adicionar foto
                        backgroundColor: Colors.grey[200], // CORRIGIDO AQUI
                        child: Icon(Icons.person, size: 60, color: Colors.grey[600]), // Ajustado para um tom mais escuro
                      ),
                      Material(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Editar foto do perfil (a implementar).')),
                             );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(driverName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                   Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Theme.of(context).colorScheme.secondary, size: 20),
                      const SizedBox(width: 4),
                      Text(driverRating, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Text('(Sua Avaliação)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildProfileInfoCard(context, 'Informações Pessoais', [ // Passando 'context'
              _buildInfoRow(context, Icons.email_outlined, 'Email', driverEmail), // Passando 'context'
              _buildInfoRow(context, Icons.phone_outlined, 'Telefone', driverPhone), // Passando 'context'
            ]),
            const SizedBox(height: 20),
            _buildProfileInfoCard(context, 'Informações do Veículo', [ // Passando 'context'
              _buildInfoRow(context, Icons.motorcycle_outlined, 'Modelo', vehicleModel), // Passando 'context'
              _buildInfoRow(context, Icons.pin_outlined, 'Placa', licensePlate), // Passando 'context'
            ]),
            const SizedBox(height: 20),
             _buildProfileInfoCard(context, 'Documentos', [ // Passando 'context'
              _buildInfoRow(context, Icons.badge_outlined, 'CNH', 'Válida até 20/10/2025', action: () { // Passando 'context'
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visualizar/Atualizar CNH (a implementar).')),
                );
              }),
              _buildInfoRow(context, Icons.description_outlined, 'CRLV', 'Atualizado', action: () { // Passando 'context'
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visualizar/Atualizar CRLV (a implementar).')),
                );
              }),
            ]),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Editar Informações'),
                onPressed: () {
                  // Navegar para uma tela de edição de perfil
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tela de edição de perfil a ser implementada.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método _buildProfileInfoCard já recebe e usa 'context'
  Widget _buildProfileInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  // CORRIGIDO: Adicionado BuildContext context como parâmetro
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {VoidCallback? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (action != null)
            IconButton(
              // CORRIGIDO: 'context' agora está disponível aqui
              icon: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).primaryColor),
              onPressed: action,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
        ],
      ),
    );
  }
}