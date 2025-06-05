// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // <<< IMPORTAR PACOTE LOTTIE
import '../providers/auth_provider.dart'; // Certifique-se que o caminho está correto

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final Color _mainAppColor = const Color(0xFF009688);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      bool loggedIn = await authProvider.login(
        _cpfController.text,
        _passwordController.text,
      );
      if (loggedIn && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _mainAppColor,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Header com Animação Lottie
            Container(
              height: screenHeight * 0.30, // Altura do header
              width: double.infinity,
              color: _mainAppColor,
              child: Center(
                // <<< SUBSTITUINDO O ÍCONE PELA ANIMAÇÃO LOTTIE >>>
                child: Lottie.asset(
                  'assets/animations/entregador.json',
                  height: screenHeight * 0.22, // Ajuste a altura da animação conforme necessário
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback caso a animação não carregue
                    return Icon(
                      Icons.delivery_dining_outlined, // Um ícone alternativo
                      color: Colors.white,
                      size: 80,
                    );
                  },
                ),
              ),
            ),
            // Corpo Branco Arredondado com Formulário
            Container(
              constraints: BoxConstraints(minHeight: screenHeight * 0.70),
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35.0),
                  topRight: Radius.circular(35.0),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.start, // Removido para centralizar o título
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // <<< TEXTO DE BOAS-VINDAS ALTERADO E CENTRALIZADO >>>
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0), // Adiciona um padding lateral se necessário
                      child: Text(
                        'Eaee motoca, Vamos começar os trampos ?',
                        textAlign: TextAlign.center, // Centraliza o texto
                        style: TextStyle(
                          fontSize: 24, // Ajustado para caber melhor
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[850],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Campo CPF (mantido o alinhamento do label à esquerda por consistência)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CPF',
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cpfController,
                      decoration: InputDecoration(
                        hintText: '000.000.000-00',
                        prefixIcon: Icon(Icons.badge_outlined, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                        CpfInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu CPF';
                        }
                        String cleanCpf = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleanCpf.length != 11) {
                          return 'CPF deve conter 11 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    // Campo Senha (mantido o alinhamento do label à esquerda)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Senha',
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Sua senha de 8 dígitos',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 15.0),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        if (value.length != 8) {
                          return 'A senha deve ter 8 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    _isLoading
                        ? Center(child: CircularProgressIndicator(color: _mainAppColor))
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mainAppColor,
                                padding: const EdgeInsets.symmetric(vertical: 18.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'ENTRAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Máscara de CPF (mantida do seu código original)
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    StringBuffer maskedText = StringBuffer();

    for (int i = 0; i < newText.length; i++) {
      maskedText.write(newText[i]);
      if (i == 2 || i == 5) {
        if (i != newText.length -1) {
          maskedText.write('.');
        }
      } else if (i == 8) {
        if (i != newText.length -1) {
          maskedText.write('-');
        }
      }
    }

    int selectionIndex = maskedText.length;

    return TextEditingValue(
      text: maskedText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}