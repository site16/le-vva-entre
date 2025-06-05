// TODO Implement this library.
// screens/help_screen.dart
// Localização: lib/screens/help_screen.dart
// Fornece uma seção de Ajuda e Suporte com FAQs e opções de contato.
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
 static const routeName = '/help';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajuda e Suporte'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text(
            'Perguntas Frequentes (FAQ)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildFaqItem(
            context,
            'Como altero meus dados cadastrais?',
            'Você pode alterar seus dados cadastrais na seção "Meu Perfil". Alguns dados, como CPF, podem necessitar de aprovação da nossa equipe.',
          ),
          _buildFaqItem(
            context,
            'Como funciona o LevvaPay?',
            'O LevvaPay é sua carteira digital no app. Todos os ganhos de corridas e entregas são creditados lá. Você pode solicitar saques para sua conta bancária cadastrada, de acordo com as políticas de saque.',
          ),
           _buildFaqItem(
            context,
            'Não estou recebendo chamados, o que fazer?',
            'Verifique se você está online no aplicativo e com uma boa conexão de internet. Certifique-se de que as permissões de localização estão ativadas para o app. Se o problema persistir, entre em contato com o suporte.',
          ),
          _buildFaqItem(
            context,
            'O que fazer se tiver um problema durante uma corrida/entrega?',
            'Em caso de emergência, contate as autoridades locais primeiro (Polícia: 190, SAMU: 192). Para problemas com o app, com o pedido/passageiro ou para reportar incidentes, utilize a opção "Problemas com o chamado?" na tela da corrida ativa ou entre em contato conosco pela Central de Ajuda.',
          ),
          _buildFaqItem(
            context,
            'Como minha avaliação é calculada?',
            'Sua avaliação é baseada no feedback dos clientes e estabelecimentos parceiros após cada serviço concluído. Boas práticas, cordialidade e eficiência contribuem para uma melhor avaliação.',
          ),
          const Divider(height: 30, thickness: 1),
          Text(
            'Entre em Contato',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
            title: const Text('Enviar um Email'),
            subtitle: const Text('suporte.entregador@levva.com.br'), // Email de exemplo
            onTap: () {
              // Lógica para abrir cliente de email
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir cliente de email (a implementar).')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.phone_outlined, color: Theme.of(context).primaryColor),
            title: const Text('Ligar para Suporte'),
            subtitle: const Text('0800 123 4567 (Entregadores)'), // Telefone de exemplo
            onTap: () {
              // Lógica para discar número
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Discar número (a implementar).')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
            title: const Text('Chat Online (Suporte)'),
            subtitle: const Text('Disponível 24/7 no app'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir chat de suporte (a implementar).')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card( // Envolve cada FAQ em um Card para melhor visualização
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ExpansionTile(
        iconColor: Theme.of(context).primaryColor,
        collapsedIconColor: Theme.of(context).primaryColorDark,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: const Border(), // Remove a borda padrão do ExpansionTile dentro do Card
        collapsedShape: const Border(),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
            child: Text(
              answer,
              textAlign: TextAlign.justify,
              style: const TextStyle(height: 1.5),
            ),
          )
        ],
      ),
    );
  }
}