// TODO Implement this library.
// screens/terms_of_use_screen.dart
// Localização: lib/screens/terms_of_use_screen.dart
// Exibe os termos e condições de uso do aplicativo.
import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});
  static const routeName = '/terms';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Termos e Condições de Uso - Levva Entregador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Última atualização: 29 de Maio de 2025', // Ajuste a data
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              '1. Aceitação dos Termos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ao se cadastrar e utilizar o aplicativo Levva Entregador ("Aplicativo"), você concorda em cumprir e estar vinculado a estes Termos e Condições de Uso ("Termos"). Se você não concorda com estes Termos, não utilize o Aplicativo.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '2. Serviços Oferecidos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'O Aplicativo Levva Entregador conecta entregadores parceiros a usuários que necessitam de serviços de transporte de passageiros (modalidade similar ao Uber Moto), entrega rápida de objetos (modalidade similar ao 99 Entregas) e delivery de comida de estabelecimentos parceiros (modalidade similar ao iFood).',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '3. Cadastro do Entregador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Para se tornar um entregador parceiro, você deve fornecer informações precisas e completas durante o processo de cadastro, incluindo, mas não se limitando a, nome completo, CNH válida, informações do veículo, e outros documentos que possam ser solicitados. Você é responsável por manter suas informações atualizadas.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '4. Responsabilidades do Entregador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '4.1. Manter a documentação do veículo e pessoal em dia.\n'
              '4.2. Cumprir todas as leis de trânsito aplicáveis.\n'
              '4.3. Prestar os serviços de forma profissional e cortês.\n'
              '4.4. Garantir a segurança e integridade dos passageiros e/ou das entregas.\n'
              '4.5. Utilizar equipamentos de segurança adequados (ex: capacete).',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '5. Pagamentos (LevvaPay)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Os pagamentos pelos serviços prestados serão processados através da plataforma LevvaPay, integrada ao Aplicativo. Os detalhes sobre taxas, repasses e condições de saque estarão disponíveis na seção LevvaPay do Aplicativo e podem ser atualizados periodicamente.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '6. Avaliações e Desempenho',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Sua avaliação e desempenho são importantes para a plataforma. Manter uma boa avaliação e um alto nível de aceitação de chamados pode influenciar a quantidade e a qualidade dos chamados oferecidos a você. A Levva reserva-se o direito de desativar contas com desempenho consistentemente baixo, conforme detalhado em nossas políticas.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '7. Limitação de Responsabilidade',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A Levva não se responsabiliza por quaisquer danos diretos, indiretos, incidentais, especiais ou consequenciais resultantes do uso ou da incapacidade de usar o Aplicativo ou os serviços.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '8. Modificações nos Termos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'A Levva reserva-se o direito de modificar estes Termos a qualquer momento. As modificações entrarão em vigor após a publicação no Aplicativo. É sua responsabilidade revisar os Termos periodicamente.',
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 16),
            Text(
              '9. Contato',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Em caso de dúvidas sobre estes Termos, entre em contato conosco através da seção "Ajuda" no Aplicativo.',
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}