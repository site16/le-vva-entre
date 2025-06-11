import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/vehicle_type_enum.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    final driver = Provider.of<AuthProvider>(context, listen: false).currentDriver;
    _emailController = TextEditingController(text: driver?.email ?? '');
    _phoneController = TextEditingController(text: driver?.phone ?? '');
    _profileImageUrl = driver?.profileImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final driver = Provider.of<AuthProvider>(context).currentDriver;

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meu Perfil'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Nenhum entregador autenticado.'),
        ),
      );
    }

    final isMoto = driver.vehicleType == VehicleType.moto;
    final isBike = driver.vehicleType == VehicleType.bike;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto do Perfil e Botão editar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                        ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                        : null,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () {
                        // Implementar lógica de trocar foto
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Função de alterar foto ainda não implementada')),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        radius: 18,
                        child: const Icon(Icons.edit, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Nome completo
              Text(
                driver.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              const SizedBox(height: 6),
              // Avaliação
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber[700], size: 21),
                  const SizedBox(width: 4),
                  Text(
                    driver.rating.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(width: 4),
                  const Text('(avaliação)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 28),
              // Dados Pessoais
              _sectionCard(
                context,
                title: 'Dados Pessoais',
                children: [
                  _profileField(Icons.badge_outlined, 'CPF', driver.cpf ?? '', enabled: false),
                  _profileField(Icons.calendar_today_outlined, 'Data de Nascimento', driver.birthDate ?? '', enabled: false),
                  _profileField(Icons.phone_outlined, 'Celular (WhatsApp)', '', // valor nunca null
                      controller: _phoneController, enabled: true),
                  _profileField(Icons.email_outlined, 'E-mail', '', // valor nunca null
                      controller: _emailController, enabled: true),
                ],
              ),
              const SizedBox(height: 16),
              if (isMoto)
                _sectionCard(
                  context,
                  title: 'Documentos Pessoais',
                  children: [
                    _imageField(
                      context,
                      icon: Icons.badge_outlined,
                      label: 'Foto da CNH',
                      imageUrl: driver.cnhImageUrl ?? '',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visualização da CNH não implementada.')),
                        );
                      },
                    ),
                  ],
                ),
              if (isBike)
                _sectionCard(
                  context,
                  title: 'Documentos Pessoais',
                  children: [
                    _imageField(
                      context,
                      icon: Icons.image,
                      label: 'Documento Pessoal (CPF ou RG)',
                      imageUrl: driver.docImageUrl ?? '',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Visualização do documento não implementada.')),
                        );
                      },
                    ),
                    if ((driver.cnhOpcionalImageUrl ?? '').isNotEmpty)
                      _imageField(
                        context,
                        icon: Icons.badge_outlined,
                        label: 'CNH (opcional)',
                        imageUrl: driver.cnhOpcionalImageUrl ?? '',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Visualização da CNH não implementada.')),
                          );
                        },
                      ),
                  ],
                ),
              if (isMoto)
                ...[
                  const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    title: 'Dados da Moto',
                    children: [
                      _imageField(
                        context,
                        icon: Icons.motorcycle,
                        label: 'Foto da Moto',
                        imageUrl: driver.vehiclePhotoUrl ?? '',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Visualização da foto da moto não implementada.')),
                          );
                        },
                      ),
                      _profileField(Icons.motorcycle_outlined, 'Modelo', driver.vehicleModel ?? '', enabled: false),
                      _profileField(Icons.palette_outlined, 'Cor', driver.vehicleColor ?? '', enabled: false),
                      _profileField(Icons.pin_outlined, 'Placa', driver.licensePlate ?? '', enabled: false),
                      _profileField(Icons.confirmation_num_outlined, 'Renavam', driver.renavam ?? '', enabled: false),
                    ],
                  ),
                ],
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Atualizar telefone/email
                          // Chame o AuthProvider para salvar as alterações
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dados salvos com sucesso!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Solicitar alteração'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Entre em contato com o suporte para solicitar alteração cadastral.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        foregroundColor: Theme.of(context).primaryColor,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
            const Divider(height: 22, thickness: 1.2),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _profileField(IconData icon, String label, String value, {TextEditingController? controller, bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: controller != null
                ? TextFormField(
                    controller: controller,
                    enabled: enabled,
                    decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    validator: (val) {
                      if (enabled && (val == null || val.isEmpty)) {
                        return 'Obrigatório';
                      }
                      return null;
                    },
                  )
                : InputDecorator(
                    decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    child: Text(
                      value ?? '', // <-- Corrigido para sempre String
                      style: TextStyle(fontWeight: enabled ? FontWeight.normal : FontWeight.bold, color: enabled ? Colors.black : Colors.black87, fontSize: 15),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _imageField(BuildContext context, {required IconData icon, required String label, String imageUrl = '', required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          if (imageUrl.isNotEmpty)
            InkWell(
              onTap: onPressed,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 36, color: Colors.grey),
                ),
              ),
            )
          else
            const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}