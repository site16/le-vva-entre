// lib/widgets/swipe_to_confirm_button.dart
import 'package:flutter/material.dart';

class SwipeToConfirmButton extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final double height;
  final Color trackColor;
  final Color thumbColor;
  final Color textColor;
  final IconData initialIcon;

  const SwipeToConfirmButton({
    super.key,
    required this.text,
    required this.onConfirm,
    this.height = 60.0,
    this.trackColor = const Color(0xFF009688), // Verde (Teal)
    this.thumbColor = const Color.fromARGB(255, 255, 254, 254),
    this.textColor = Colors.white,
    this.initialIcon = Icons.double_arrow_rounded,
  });

  @override
  State<SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<SwipeToConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragPosition = 0.0;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (_isConfirmed || !mounted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, trackWidth);
    });
  }

  /// *** MÉTODO CORRIGIDO PARA NÃO TRAVAR O BOTÃO ***
  void _onDragEnd(DragEndDetails details, double trackWidth) {
    if (_isConfirmed) return;
    final confirmationThreshold = trackWidth * 0.8;

    if (_dragPosition > confirmationThreshold) {
      // 1. Mostra o feedback visual de confirmação
      setState(() {
        _isConfirmed = true;
        _dragPosition = trackWidth;
      });

      // 2. Espera um momento para o usuário ver o feedback...
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // 3. ...Dispara a ação principal (ex: abrir o diálogo)
          widget.onConfirm();

          // 4. E IMEDIATAMENTE reseta o estado visual do botão.
          // A abertura do diálogo vai "mascarar" este retorno,
          // garantindo que o botão não fique travado.
          setState(() {
            _dragPosition = 0.0;
            _isConfirmed = false;
          });
        }
      });
    } else {
      // Se não confirmou, anima o botão de volta à posição inicial.
      final animation =
          Tween<double>(begin: _dragPosition, end: 0.0).animate(
              CurvedAnimation(
                  parent: _animationController, curve: Curves.easeOut));

      animation.addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = animation.value;
          });
        }
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - widget.height;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.trackColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: (1 - (_dragPosition / (widget.height * 2.5))).clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 100),
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details, trackWidth),
                  onHorizontalDragEnd: (details) =>
                      _onDragEnd(details, trackWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.height,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: _isConfirmed ? widget.trackColor : widget.thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.15),
                           blurRadius: 4,
                           spreadRadius: 1
                         )
                      ]
                    ),
                    child: Icon(
                      _isConfirmed ? Icons.check_rounded : widget.initialIcon,
                      color: _isConfirmed ? widget.thumbColor : widget.trackColor,
                      size: widget.height * 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}