import 'package:flutter/material.dart';
// import 'package:pao_tracker/utils/colors.dart'; // No longer needed

class FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final ValueChanged<bool> onChanged;
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onChanged,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late bool _fav;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _fav = widget.isFavorite;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (_fav) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      _fav = widget.isFavorite;
      if (_fav)
        _controller.forward();
      else
        _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _fav = !_fav);
    if (_fav)
      _controller.forward();
    else
      _controller.reverse();
    widget.onChanged(_fav);
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: _toggle,
      tooltip: _fav ? 'Unfavorite' : 'Mark favorite',
      iconSize: 28,
      icon: ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final color = Color.lerp(
              // --- UPDATED: Use theme colors ---
              colorScheme.onSurfaceVariant,
              colorScheme.error,
              _controller.value,
            )!;
            return Icon(
              _fav ? Icons.favorite : Icons.favorite_border,
              color: color,
            );
          },
        ),
      ),
    );
  }
}