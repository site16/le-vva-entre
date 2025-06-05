// lib/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; // <<< IMPORTAR PACOTE LOTTIE
import '../models/wallet_transaction_model.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  static const routeName = '/wallet';
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isBalanceVisible = true;
  final NumberFormat _currencyFormatter = NumberFormat.simpleCurrency(
    locale: 'pt_BR',
  );
  bool _showFeeDetailsInSheet = false;

  Future<void> _showSuccessDialogAfterWithdrawal(
    double netAmountReceived,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // <<< AJUSTES NO PADDING E CONTEÚDO DO TÍTULO PARA A ANIMAÇÃO >>>
          titlePadding: const EdgeInsets.only(top: 20.0, bottom: 0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/valeu.json',
                height: 80, // Ajuste a altura conforme necessário
                width: 80, // Ajuste a largura conforme necessário
                fit: BoxFit.contain,
                repeat: false, // Para a animação rodar uma vez
                errorBuilder: (context, error, stackTrace) {
                  // Fallback caso a animação não carregue
                  return const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF009688),
                    size: 35,
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text('Solicitação Enviada!', textAlign: TextAlign.center),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Sua solicitação de saque foi recebida e será processada pela nossa equipe.',
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center, // Adicionado para consistência
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center, // Adicionado para consistência
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'O valor de '),
                      TextSpan(
                        text: _currencyFormatter.format(netAmountReceived),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' será depositado na sua conta bancária informada em até ',
                      ),
                      const TextSpan(
                        text: '1 dia útil',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawalDialog(BuildContext context, WalletProvider provider) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    _showFeeDetailsInSheet = false; // Reseta ao abrir o bottom sheet

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext modalContext, StateSetter setModalState) {
            double requestedAmount =
                double.tryParse(amountController.text.replaceAll(',', '.')) ??
                0.0;
            Map<String, double> details = provider.calculateWithdrawalDetails(
              requestedAmount,
            );

            double netAmountToReceive = details['netAmountToReceive'] ?? 0.0;
            double totalDebitFromOnline =
                details['totalDebitFromOnline'] ??
                0.0; // Este é o valor que será debitado

            // Recalcula as taxas baseadas no valor bruto para exibição, como no seu código original
            // No entanto, as taxas reais são calculadas em calculateWithdrawalDetails
            double displayMaintenanceFeeValue =
                provider.grossEarningsForCommission *
                provider.maintenanceFeePercentage;
            double displayTransferFeeValue =
                provider.grossEarningsForCommission *
                provider.transferFeePercentage;

            // Arredondamento para exibição
            displayMaintenanceFeeValue =
                (displayMaintenanceFeeValue * 100).roundToDouble() / 100;
            displayTransferFeeValue =
                (displayTransferFeeValue * 100).roundToDouble() / 100;

            bool canProceed =
                requestedAmount > 0 &&
                totalDebitFromOnline <=
                    provider
                        .onlineBalance && // Verifica se o débito total é coberto
                netAmountToReceive > 0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.0),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const Text(
                        'Quero sacar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: amountController,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'R\$ 0,00',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Informe um valor.';
                          final amount =
                              double.tryParse(value.replaceAll(',', '.')) ??
                              0.0;
                          if (amount <= 0) return 'Valor inválido.';

                          // Re-calcula detalhes para validação precisa
                          final validationDetails = provider
                              .calculateWithdrawalDetails(amount);
                          final validationTotalDebit =
                              validationDetails['totalDebitFromOnline'] ?? 0.0;
                          final validationNetAmount =
                              validationDetails['netAmountToReceive'] ?? 0.0;

                          if (validationTotalDebit > provider.onlineBalance) {
                            return 'Saldo LevvaPay (${_currencyFormatter.format(provider.onlineBalance)}) insuficiente para cobrir valor + taxas.';
                          }
                          if (validationNetAmount <= 0) {
                            double totalCommissionForDisplay =
                                (provider.grossEarningsForCommission *
                                        provider.totalCommissionRate *
                                        100)
                                    .roundToDouble() /
                                100;
                            return 'Valor não cobre as taxas (${_currencyFormatter.format(totalCommissionForDisplay)}).';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setModalState(() {
                            // A lógica de _showFeeDetailsInSheet e formKey.currentState!.validate() é para mostrar
                            // os detalhes das taxas dinamicamente e revalidar o campo.
                            final currentAmount =
                                double.tryParse(
                                  amountController.text.replaceAll(',', '.'),
                                ) ??
                                0.0;
                            if (currentAmount > 0 && !_showFeeDetailsInSheet) {
                              _showFeeDetailsInSheet = true;
                            } else if (currentAmount <= 0 &&
                                _showFeeDetailsInSheet) {
                              _showFeeDetailsInSheet = false;
                            }
                            if (formKey.currentState != null) {
                              formKey.currentState!.validate();
                            }
                          });
                        },
                      ),
                      Divider(color: Colors.grey.shade300, height: 20),
                      const SizedBox(height: 16),

                      if (requestedAmount >
                          0) // Mostra apenas se houver valor digitado
                        _buildDetailRowSheet(
                          'Valor Solicitado:',
                          requestedAmount,
                        ), // Mostra o valor bruto solicitado

                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: AnimatedOpacity(
                          opacity: _showFeeDetailsInSheet ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child:
                              _showFeeDetailsInSheet
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      _buildDetailRowSheet(
                                        'Taxa de manutenção (${(provider.maintenanceFeePercentage * 100).toStringAsFixed(0)}%):',
                                        displayMaintenanceFeeValue,
                                        isFee: true,
                                      ),
                                      _buildDetailRowSheet(
                                        'Taxa de transferência (${(provider.transferFeePercentage * 100).toStringAsFixed(1)}%):',
                                        displayTransferFeeValue,
                                        isFee: true,
                                      ),
                                      const SizedBox(height: 8),
                                      Divider(
                                        color: Colors.grey.shade200,
                                        height: 10,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRowSheet(
                                        'Você recebe:',
                                        netAmountToReceive,
                                        isTotal: true,
                                        highlightTotal: true,
                                      ),
                                    ],
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              canProceed
                                  ? () {
                                    if (formKey.currentState!.validate()) {
                                      Navigator.of(modalContext).pop();
                                      provider
                                          .requestWithdrawal(requestedAmount)
                                          .then((_) {
                                            _showSuccessDialogAfterWithdrawal(
                                              netAmountToReceive,
                                            );
                                          })
                                          .catchError((error) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    error
                                                        .toString()
                                                        .replaceFirst(
                                                          "Exception: ",
                                                          "",
                                                        ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          });
                                    }
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Confirmar Saque'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRowSheet(
    String label,
    double value, {
    bool isTotal = false,
    bool isFee = false,
    bool highlightTotal = false,
  }) {
    final Color valueColor =
        isFee
            ? Colors.red.shade600
            : (highlightTotal ? const Color(0xFF00796B) : Colors.black87);
    final String prefix = isFee && value > 0 ? '- ' : (isTotal ? '' : '');
    final FontWeight fontWeight =
        (isTotal || highlightTotal) ? FontWeight.bold : FontWeight.normal;
    final double fontSize = (isTotal || highlightTotal) ? 16 : 14;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          Text(
            prefix + _currencyFormatter.format(value.abs()),
            style: TextStyle(
              color: valueColor,
              fontWeight: fontWeight,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    const Color primaryColor = Color(0xFF009688);
    const Color primaryColorDark = Color(0xFF00796B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Minha Carteira',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => walletProvider.fetchWalletData(),
        color: Colors.white,
        backgroundColor: primaryColor,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: const LinearGradient(
                  colors: [primaryColor, primaryColorDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LevvaPay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isBalanceVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                          size: 22,
                        ),
                        onPressed:
                            () => setState(
                              () => _isBalanceVisible = !_isBalanceVisible,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                    child: Text(
                      _isBalanceVisible
                          ? _currencyFormatter.format(
                            walletProvider.onlineBalance,
                          )
                          : 'R\$ ••••••',
                      key: ValueKey<String>(
                        'levvapay_${_isBalanceVisible}_${walletProvider.onlineBalance}',
                      ),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dinheiro/Maquininha',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (child, animation) => FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: Text(
                                _isBalanceVisible
                                    ? _currencyFormatter.format(
                                      walletProvider.cashBalance,
                                    )
                                    : "R\$ ••••••",
                                key: ValueKey<String>(
                                  'cash_${_isBalanceVisible}_${walletProvider.cashBalance}',
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo Bruto', // Referente a comissão bruta
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (child, animation) => FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                              child: Text(
                                _isBalanceVisible
                                    ? _currencyFormatter.format(
                                      walletProvider.grossEarningsForCommission,
                                    )
                                    : "R\$ ••••••",
                                key: ValueKey<String>(
                                  'gross_${_isBalanceVisible}_${walletProvider.grossEarningsForCommission}',
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Depositar'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Função "Depositar" em desenvolvimento.',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Sacar',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed:
                        walletProvider.onlineBalance > 0
                            ? () =>
                                _showWithdrawalDialog(context, walletProvider)
                            : null, // Desabilitar se saldo for 0
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor:
                          Colors.grey.shade400, // Cor quando desabilitado
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Últimas Movimentações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            if (walletProvider.isLoading && walletProvider.transactions.isEmpty)
              const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            else if (walletProvider.transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Nenhuma transação encontrada.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: walletProvider.transactions.length,
                separatorBuilder:
                    (_, __) => Divider(
                      color: Colors.grey.shade200,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                itemBuilder: (ctx, index) {
                  final tx = walletProvider.transactions[index];
                  IconData txIcon = Icons.receipt_long_outlined;
                  Color txColor = Colors.grey.shade700;

                  switch (tx.type) {
                    case TransactionType.creditOnlineEarning:
                    case TransactionType.infoCashEarning:
                      txIcon = Icons.arrow_downward_rounded;
                      txColor = Colors.green.shade700;
                      break;
                    case TransactionType.debitWithdrawalFromOnline:
                      txIcon = Icons.arrow_upward_rounded;
                      txColor = Colors.red.shade700;
                      break;
                    case TransactionType.creditManualAdjustment:
                      txIcon = Icons.card_giftcard_rounded;
                      txColor = Colors.blue.shade600;
                      break;
                    case TransactionType.debitManualAdjustment:
                      txIcon = Icons.remove_circle_outline_rounded;
                      txColor = Colors.orange.shade700;
                      break;
                    default:
                      txIcon =
                          tx.amount >= 0
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline;
                      txColor =
                          tx.amount >= 0
                              ? Colors.green.shade600
                              : Colors.red.shade600;
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: txColor.withOpacity(0.1),
                      child: Icon(txIcon, color: txColor, size: 22),
                    ),
                    title: Text(
                      tx.description,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat(
                        'dd/MM/yy \'•\' HH:mm',
                        'pt_BR',
                      ).format(tx.date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      (tx.amount < 0 ? "- " : "+ ") +
                          _currencyFormatter.format(tx.amount.abs()),
                      style: TextStyle(
                        color:
                            tx.amount < 0
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
