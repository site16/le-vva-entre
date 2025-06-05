import 'package:flutter/material.dart';

class UserRatingDialog extends StatefulWidget {
  final String userName;
  final Function(int rating, List<String> motivos, String comentario, bool bloquear) onSend;

  const UserRatingDialog({
    Key? key,
    required this.userName,
    required this.onSend,
  }) : super(key: key);

  @override
  State<UserRatingDialog> createState() => _UserRatingDialogState();
}

class _UserRatingDialogState extends State<UserRatingDialog> {
  int _rating = 0;
  List<String> _motivosSelecionados = [];
  String _comentario = '';
  bool _bloquearUsuario = false;

  final List<String> opcoesNegativas = [
    'Mal educado',
    'Estragou veículo',
    'Atrasou retirada',
    'Pagamento problemático',
    'Outro',
  ];
  final List<String> opcoesPositivas = [
    'Educado',
    'Rápido na entrega',
    'Pagamento em dia',
    'Boa comunicação',
    'Outro',
  ];

  List<String> get _opcoes =>
      _rating >= 4 ? opcoesPositivas : (_rating > 0 ? opcoesNegativas : []);

  void _toggleMotivo(String motivo) {
    setState(() {
      if (_motivosSelecionados.contains(motivo)) {
        _motivosSelecionados.remove(motivo);
      } else {
        _motivosSelecionados.add(motivo);
      }
    });
  }

  void _enviarAvaliacao() {
    widget.onSend(_rating, _motivosSelecionados, _comentario, _bloquearUsuario);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Avaliar ${widget.userName}'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  _rating > i ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() {
                  _rating = i + 1;
                  _motivosSelecionados.clear();
                }),
              )),
            ),
            if (_rating > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _rating < 4
                    ? "O que aconteceu?"
                    : "O que teve de bom?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (_rating > 0)
              Wrap(
                spacing: 8,
                children: _opcoes.map((motivo) => ChoiceChip(
                  label: Text(motivo),
                  selected: _motivosSelecionados.contains(motivo),
                  onSelected: (_) => _toggleMotivo(motivo),
                )).toList(),
              ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Comentário (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (v) => setState(() => _comentario = v),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _bloquearUsuario,
                  onChanged: (v) => setState(() => _bloquearUsuario = v!),
                ),
                Flexible(child: Text("Bloquear este usuário para não receber mais pedidos dele")),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _rating == 0 ? null : _enviarAvaliacao,
          icon: Icon(Icons.send),
          label: Text('Avaliar'),
        ),
      ],
    );
  }
}