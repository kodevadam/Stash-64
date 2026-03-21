import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// An on-screen touch keyboard that can be shown below text fields.
/// Supports letters, numbers, symbols, backspace, space, and enter.
class TouchKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onDone;

  const TouchKeyboard({
    super.key,
    required this.controller,
    this.focusNode,
    this.onDone,
  });

  @override
  State<TouchKeyboard> createState() => _TouchKeyboardState();
}

class _TouchKeyboardState extends State<TouchKeyboard> {
  bool _showSymbols = false;
  bool _capsLock = false;

  static const _letterRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static const _symbolRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['-', '/', ':', ';', '(', ')', '\$', '&', '@', '"'],
    ['.', ',', '?', '!', "'", '#', '%', '+', '='],
  ];

  void _onKey(String key) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    String newText;
    int newCursorPos;

    if (selection.isValid && selection.start != selection.end) {
      // Replace selection
      newText = text.replaceRange(selection.start, selection.end, key);
      newCursorPos = selection.start + key.length;
    } else {
      final cursorPos = selection.isValid ? selection.baseOffset : text.length;
      newText = text.substring(0, cursorPos) + key + text.substring(cursorPos);
      newCursorPos = cursorPos + key.length;
    }

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  void _onBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid && selection.start != selection.end) {
      final newText = text.replaceRange(selection.start, selection.end, '');
      widget.controller.text = newText;
      widget.controller.selection =
          TextSelection.collapsed(offset: selection.start);
    } else {
      final cursorPos = selection.isValid ? selection.baseOffset : text.length;
      if (cursorPos > 0) {
        final newText =
            text.substring(0, cursorPos - 1) + text.substring(cursorPos);
        widget.controller.text = newText;
        widget.controller.selection =
            TextSelection.collapsed(offset: cursorPos - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _showSymbols ? _symbolRows : _letterRows;

    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1
          _buildRow(rows[0]),
          const SizedBox(height: 6),
          // Row 2
          _buildRow(rows[1]),
          const SizedBox(height: 6),
          // Row 3 with shift / backspace
          _buildRow3(rows[2]),
          const SizedBox(height: 6),
          // Bottom row: symbols toggle, space, done
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys
          .map((k) => _buildKey(
                _capsLock || _showSymbols ? k : k.toLowerCase(),
                onTap: () =>
                    _onKey(_capsLock || _showSymbols ? k : k.toLowerCase()),
              ))
          .toList(),
    );
  }

  Widget _buildRow3(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Caps lock / shift
        if (!_showSymbols)
          _buildKey(
            _capsLock ? 'CAPS' : 'caps',
            width: 56,
            color: _capsLock ? AppTheme.accentGold : null,
            onTap: () => setState(() => _capsLock = !_capsLock),
          ),
        ...keys.map((k) => _buildKey(
              _capsLock || _showSymbols ? k : k.toLowerCase(),
              onTap: () =>
                  _onKey(_capsLock || _showSymbols ? k : k.toLowerCase()),
            )),
        // Backspace
        _buildKey(
          '',
          width: 56,
          icon: Icons.backspace_outlined,
          onTap: _onBackspace,
          onLongPress: () {
            widget.controller.clear();
          },
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Symbol toggle
        _buildKey(
          _showSymbols ? 'ABC' : '123',
          width: 64,
          onTap: () => setState(() => _showSymbols = !_showSymbols),
        ),
        // Space bar
        _buildKey(
          'space',
          width: 200,
          onTap: () => _onKey(' '),
        ),
        // Done
        _buildKey(
          'Done',
          width: 64,
          color: AppTheme.accentGold,
          textColor: AppTheme.primaryDark,
          onTap: widget.onDone,
        ),
      ],
    );
  }

  Widget _buildKey(
    String label, {
    double width = 36,
    IconData? icon,
    Color? color,
    Color? textColor,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: width,
        height: 48,
        child: Material(
          color: color ?? AppTheme.cardDark,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 20, color: textColor ?? AppTheme.textPrimary)
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: label.length > 3 ? 12 : 16,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? AppTheme.textPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A helper widget that wraps a TextField with an optional on-screen keyboard.
/// Shows a small keyboard icon button; tapping it toggles the keyboard below.
class TouchKeyboardField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const TouchKeyboardField({
    super.key,
    required this.controller,
    this.decoration,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<TouchKeyboardField> createState() => _TouchKeyboardFieldState();
}

class _TouchKeyboardFieldState extends State<TouchKeyboardField> {
  bool _showKeyboard = false;
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add keyboard toggle icon to decoration
    final baseDecoration = widget.decoration ?? const InputDecoration();
    final decoration = baseDecoration.copyWith(
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (baseDecoration.suffixIcon != null) baseDecoration.suffixIcon!,
          IconButton(
            icon: Icon(
              _showKeyboard ? Icons.keyboard_hide : Icons.keyboard,
              color: _showKeyboard
                  ? AppTheme.accentGold
                  : AppTheme.textSecondary,
              size: 22,
            ),
            onPressed: () => setState(() => _showKeyboard = !_showKeyboard),
            tooltip: _showKeyboard ? 'Hide keyboard' : 'Show keyboard',
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: decoration,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          readOnly: _showKeyboard,
          showCursor: true,
          onTap: () {
            if (!_showKeyboard) return;
            // Keep focus when using touch keyboard
            _focusNode.requestFocus();
          },
        ),
        if (_showKeyboard)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TouchKeyboard(
              controller: widget.controller,
              focusNode: _focusNode,
              onDone: () {
                setState(() => _showKeyboard = false);
                _focusNode.unfocus();
              },
            ),
          ),
      ],
    );
  }
}
