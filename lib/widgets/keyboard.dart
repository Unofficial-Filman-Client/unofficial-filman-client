// ignore_for_file: deprecated_member_use

import "package:flutter/material.dart";
import "package:flutter/services.dart";

class CustomKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final Function() onSubmit;
  final Function()? onUpFromFirstRow;
  final bool autoFocus;

  const CustomKeyboard({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
    this.onUpFromFirstRow,
    this.autoFocus = false,
  });

  @override
  State<CustomKeyboard> createState() => CustomKeyboardState();
}

class CustomKeyboardState extends State<CustomKeyboard> {
  bool isShiftEnabled = false;
  bool isSymbolMode = false;
  final List<List<FocusNode>> _focusNodes = [];
  
  final List<List<String>> _qwertyLayout = [
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
    ["z", "x", "c", "v", "b", "n", "m"],
  ];

  final List<List<String>> _symbolsLayout = [
    ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
    ["@", "#", "\$", "_", "&", "-", "+", "(", ")", "/"],
    ["*", '"', "'", ":", ";", "!", "?"],
  ];

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length
    );
  }

  void focusFirstKey() {
    if (_focusNodes.isNotEmpty && _focusNodes[0].isNotEmpty) {
      _focusNodes[0][0].requestFocus();
    }
  }

  void _initializeFocusNodes() {
    for (var row in _qwertyLayout) {
      _focusNodes.add(List.generate(row.length, (final _) => FocusNode()));
    }
    _focusNodes.add(List.generate(5, (final _) => FocusNode()));
  }

  @override
  void dispose() {
    for (var row in _focusNodes) {
      for (var node in row) {
        node.dispose();
      }
    }
    super.dispose();
  }

  void _onKeyTap(final String key) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final actualKey = isShiftEnabled ? key.toUpperCase() : key;
    
    final newText = selection.isCollapsed
        ? text.replaceRange(selection.start, selection.start, actualKey)
        : text.replaceRange(selection.start, selection.end, actualKey);
    
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );

    widget.onChanged(newText);
    
    if (isShiftEnabled) {
      setState(() => isShiftEnabled = false);
    }
  }

  void _handleBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    
    if (text.isEmpty) return;
    
    String newText;
    TextSelection newSelection;
    
    if (selection.isCollapsed && selection.start > 0) {
      newText = text.replaceRange(selection.start - 1, selection.start, "");
      newSelection = TextSelection.collapsed(offset: selection.start - 1);
    } else if (!selection.isCollapsed) {
      newText = text.replaceRange(selection.start, selection.end, "");
      newSelection = TextSelection.collapsed(offset: selection.start);
    } else {
      return;
    }
    
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );
    
    widget.onChanged(newText);
  }

  KeyEventResult _handleKeyEvent(final FocusNode node, final RawKeyEvent event, 
      {required final int rowIndex, required final int keyIndex, final VoidCallback? onSelect}) {
    if (event is! RawKeyDownEvent) return KeyEventResult.handled;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown && rowIndex < _focusNodes.length - 1) {
      final nextRow = _focusNodes[rowIndex + 1];
      nextRow[keyIndex.clamp(0, nextRow.length - 1)].requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (rowIndex == 0 && widget.onUpFromFirstRow != null) {
        widget.onUpFromFirstRow!();
      } else if (rowIndex > 0) {
        final prevRow = _focusNodes[rowIndex - 1];
        prevRow[keyIndex.clamp(0, prevRow.length - 1)].requestFocus();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && keyIndex > 0) {
      _focusNodes[rowIndex][keyIndex - 1].requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && 
        keyIndex < _focusNodes[rowIndex].length - 1) {
      _focusNodes[rowIndex][keyIndex + 1].requestFocus();
    } else if ((event.logicalKey == LogicalKeyboardKey.select || 
        event.logicalKey == LogicalKeyboardKey.enter) && onSelect != null) {
      onSelect();
    }
    
    return KeyEventResult.handled;
  }

  Widget _buildKey(final String letter, final FocusNode focusNode, 
      {required final int rowIndex, required final int keyIndex}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Focus(
          focusNode: focusNode,
          onKey: (final node, final event) => _handleKeyEvent(
            node, 
            event,
            rowIndex: rowIndex,
            keyIndex: keyIndex,
            onSelect: () => _onKeyTap(letter),
          ),
          child: Builder(
            builder: (final context) {
              final bool hasFocus = Focus.of(context).hasFocus;
              return _KeyButton(
                hasFocus: hasFocus,
                onTap: () => _onKeyTap(letter),
                child: Text(
                  isShiftEnabled ? letter.toUpperCase() : letter,
                  style: TextStyle(
                    fontSize: 18,
                    color: hasFocus ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(final Widget child, final VoidCallback onPressed, final FocusNode focusNode,
      {required final int rowIndex, required final int keyIndex, final int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Focus(
          focusNode: focusNode,
          onKey: (final node, final event) => _handleKeyEvent(
            node,
            event,
            rowIndex: rowIndex,
            keyIndex: keyIndex,
            onSelect: onPressed,
          ),
          child: Builder(
            builder: (final context) {
              final bool hasFocus = Focus.of(context).hasFocus;
              return _KeyButton(
                hasFocus: hasFocus,
                onTap: onPressed,
                backgroundColor: const Color(0xFF303030),
                child: IconTheme(
                  data: IconThemeData(
                    color: hasFocus ? Colors.black : Colors.white,
                    size: 20,
                  ),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final currentLayout = isSymbolMode ? _symbolsLayout : _qwertyLayout;
    
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        height: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF202020),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...List.generate(currentLayout.length, (final rowIndex) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  currentLayout[rowIndex].length,
                  (final keyIndex) => _buildKey(
                    currentLayout[rowIndex][keyIndex],
                    _focusNodes[rowIndex][keyIndex],
                    rowIndex: rowIndex,
                    keyIndex: keyIndex,
                  ),
                ),
              );
            }),
            Row(
              children: [
                _buildSpecialKey(
                  Icon(isShiftEnabled ? Icons.keyboard_capslock : Icons.keyboard_arrow_up,
                      color: isShiftEnabled ? Colors.blue : null),
                  () => setState(() => isShiftEnabled = !isShiftEnabled),
                  _focusNodes[3][0],
                  rowIndex: 3,
                  keyIndex: 0,
                ),
                _buildSpecialKey(
                  Text(
                    isSymbolMode ? "ABC" : "?123",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  () => setState(() => isSymbolMode = !isSymbolMode),
                  _focusNodes[3][1],
                  rowIndex: 3,
                  keyIndex: 1,
                ),
                _buildSpecialKey(
                  const Icon(Icons.space_bar),
                  () => _onKeyTap(" "),
                  _focusNodes[3][2],
                  rowIndex: 3,
                  keyIndex: 2,
                  flex: 4,
                ),
                _buildSpecialKey(
                  const Icon(Icons.backspace),
                  _handleBackspace,
                  _focusNodes[3][3],
                  rowIndex: 3,
                  keyIndex: 3,
                ),
                _buildSpecialKey(
                  const Icon(Icons.search),
                  widget.onSubmit,
                  _focusNodes[3][4],
                  rowIndex: 3,
                  keyIndex: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final bool hasFocus;
  final VoidCallback onTap;
  final Widget child;
  final Color? backgroundColor;

  const _KeyButton({
    required this.hasFocus,
    required this.onTap,
    required this.child,
    this.backgroundColor = const Color(0xFF424242),
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: hasFocus ? Colors.white : backgroundColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Center(child: child),
        ),
      ),
    );
  }
}