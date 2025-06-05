import 'package:flutter/material.dart';
import 'package:levva_entregador/models/vehicle_type_enum.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';

// Widget para o conteúdo do BottomSheet de Filtros
class FilterOptionsSheet extends StatefulWidget {
  const FilterOptionsSheet({super.key});

  @override
  State<FilterOptionsSheet> createState() => _FilterOptionsSheetState();
}

class _FilterOptionsSheetState extends State<FilterOptionsSheet> {
  late List<OrderType> _tempSelectedServiceTypes;
  late List<PaymentMethod> _tempSelectedPaymentMethods;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _tempSelectedServiceTypes =
        List<OrderType>.from(authProvider.currentDriver?.preferredServiceTypes ?? []);
    _tempSelectedPaymentMethods =
        List<PaymentMethod>.from(authProvider.currentDriver?.preferredPaymentMethods ?? []);
    
    if (!_tempSelectedPaymentMethods.contains(PaymentMethod.online)) { // online é o LevvaPay
      _tempSelectedPaymentMethods.add(PaymentMethod.online);
    }
  }

  String _getOrderTypeName(OrderType type) {
    switch (type) {
      case OrderType.moto: return 'Passageiros (Moto)';
      case OrderType.package: return 'Entregas Rápidas';
      case OrderType.food: return 'Delivery de Comida';
      default: return type.name.toUpperCase();
    }
  }

  String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.online:
        return 'LevvaPay (Carteira)';
      case PaymentMethod.cash:
        return 'Dinheiro';
      case PaymentMethod.cardMachine:
        return 'Cartão (Maquininha)';
      default:
        return method.toString().split('.').last;
    }
  }

  bool get isOnlyDeliveryActive =>
    _tempSelectedServiceTypes.length == 1 &&
    _tempSelectedServiceTypes.contains(OrderType.food);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final driverVehicleType = authProvider.currentDriver?.vehicleType;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Text(
                  'Filtros e Preferências',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            Text(
              "Tipos de Serviço Ativos", 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 8),
            ...OrderType.values
                .where((type) => type != OrderType.unknown)
                .where((serviceType) => !(driverVehicleType == VehicleType.bike && serviceType == OrderType.moto))
                .map((serviceType) {
              return SwitchListTile(
                title: Text(_getOrderTypeName(serviceType)),
                value: _tempSelectedServiceTypes.contains(serviceType),
                onChanged: (bool newValue) {
                  setState(() {
                    if (newValue) {
                      _tempSelectedServiceTypes.add(serviceType);
                    } else {
                      _tempSelectedServiceTypes.remove(serviceType);
                    }
                    // Garantir que LevvaPay sempre estará ativo
                    if (!_tempSelectedPaymentMethods.contains(PaymentMethod.online)) {
                      _tempSelectedPaymentMethods.add(PaymentMethod.online);
                    }
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
                dense: true,
              );
            }).toList(),

            const SizedBox(height: 20),
            Text(
              "Formas de Pagamento Aceitas", 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 8),

            // LevvaPay sempre ativo e bloqueado
            CheckboxListTile(
              title: Text(getPaymentMethodName(PaymentMethod.online)),
              value: true,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Theme.of(context).colorScheme.primary,
              tileColor: Colors.grey.shade200,
              secondary: Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 20),
            ),

            // Dinheiro
            CheckboxListTile(
              title: Text(getPaymentMethodName(PaymentMethod.cash)),
              value: _tempSelectedPaymentMethods.contains(PaymentMethod.cash),
              onChanged: isOnlyDeliveryActive
                  ? null
                  : (bool? newValue) {
                      setState(() {
                        if (newValue == true) {
                          _tempSelectedPaymentMethods.add(PaymentMethod.cash);
                        } else {
                          _tempSelectedPaymentMethods.remove(PaymentMethod.cash);
                        }
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Theme.of(context).colorScheme.primary,
            ),

            // Maquininha
            CheckboxListTile(
              title: Text(getPaymentMethodName(PaymentMethod.cardMachine)),
              value: _tempSelectedPaymentMethods.contains(PaymentMethod.cardMachine),
              onChanged: isOnlyDeliveryActive
                  ? null
                  : (bool? newValue) {
                      setState(() {
                        if (newValue == true) {
                          _tempSelectedPaymentMethods.add(PaymentMethod.cardMachine);
                        } else {
                          _tempSelectedPaymentMethods.remove(PaymentMethod.cardMachine);
                        }
                      });
                    },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Theme.of(context).colorScheme.primary,
            ),

            if (isOnlyDeliveryActive)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Para pedidos de Delivery, o pagamento é sempre online. Dinheiro e maquininha aparecem apenas como observação da loja (ex: buscar troco ou maquininha).',
                  style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),

            const Divider(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Aplicar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                onPressed: () {
                  authProvider.updateServicePreferences(_tempSelectedServiceTypes);
                  // Só salva LevvaPay se for apenas delivery
                  if (isOnlyDeliveryActive) {
                    authProvider.updatePaymentPreferences([PaymentMethod.online]);
                  } else {
                    authProvider.updatePaymentPreferences(_tempSelectedPaymentMethods);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferências salvas!'), backgroundColor: Colors.green),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// Widget HomeActionBar (principal)
class HomeActionBar extends StatelessWidget {
  const HomeActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).brightness == Brightness.dark 
                       ? Colors.white70 
                       : Colors.black54;
    final primaryIconColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: Colors.transparent, 
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile'); 
            },
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.85),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Icon(
                Icons.person_outline,
                color: iconColor,
                size: 28.0,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true, 
                builder: (BuildContext bContext) {
                  return const FilterOptionsSheet();
                },
              );
            },
            borderRadius: BorderRadius.circular(24.0),
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.85),
                shape: BoxShape.circle,
                 boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Icon(
                Icons.filter_list_alt,
                color: primaryIconColor,
                size: 28.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}