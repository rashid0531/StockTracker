import 'package:flutter/material.dart';
import '../theme.dart';

class HoverButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ThemeProvider theme;

  const HoverButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.positive : widget.theme.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isHovered ? AppColors.positive : widget.theme.border,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.positive.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: _isHovered ? Colors.white : widget.theme.text,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: _isHovered ? Colors.white : widget.theme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
