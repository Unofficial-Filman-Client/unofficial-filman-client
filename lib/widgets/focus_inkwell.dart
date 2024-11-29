import "package:flutter/material.dart";
import "package:flutter/services.dart";

class FocusInkWell extends StatefulWidget {
  final Widget Function(bool hasFocus) builder;
  final void Function()? onTap;
  final bool autofocus;

  const FocusInkWell({
    super.key,
    required this.builder,
    this.onTap,
    this.autofocus = false,
  });

  @override
  State<FocusInkWell> createState() => _FocusInkWellState();
}

class _FocusInkWellState extends State<FocusInkWell> {
  bool _isFocused = false;

  void _handleFocusChange(final bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: (final FocusNode node, final KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            if (widget.onTap != null) {
              widget.onTap!();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: widget.builder(_isFocused),
      ),
    );
  }
}
