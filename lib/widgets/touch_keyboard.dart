import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// A full-width on-screen touch keyboard designed for kiosk/touchscreen use.
/// Keys expand to fill available width. Supports letters, numbers, symbols,
/// shift, backspace (with repeat), space, and done.
class TouchKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onDone;
  final ValueChanged<String>? onTextChanged;

  const TouchKeyboard({
    super.key,
    required this.controller,
    this.focusNode,
    this.onDone,
    this.onTextChanged,
  });

  @override
  State<TouchKeyboard> createState() => _TouchKeyboardState();
}

class _TouchKeyboardState extends State<TouchKeyboard> {
  bool _showSymbols = false;
  bool _shifted = true; // Start shifted for first letter capitalization
  Timer? _backspaceTimer;

  static const _letterRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  static const _symbolRows = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['-', '/', ':', ';', '(', ')', '&', '@', '"', "'"],
    ['.', ',', '?', '!', '#', '%', '+', '=', '_'],
  ];

  @override
  void dispose() {
    _backspaceTimer?.cancel();
    super.dispose();
  }

  void _onKey(String key) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    String newText;
    int newCursorPos;

    if (selection.isValid && selection.start != selection.end) {
      newText = text.replaceRange(selection.start, selection.end, key);
      newCursorPos = selection.start + key.length;
    } else {
      final cursorPos = selection.isValid ? selection.baseOffset : text.length;
      newText = text.substring(0, cursorPos) + key + text.substring(cursorPos);
      newCursorPos = cursorPos + key.length;
    }

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: newCursorPos);
    widget.onTextChanged?.call(newText);

    // Auto-unshift after typing a letter (like a phone keyboard)
    if (_shifted && !_showSymbols) {
      setState(() => _shifted = false);
    }
  }

  void _onBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid && selection.start != selection.end) {
      final newText = text.replaceRange(selection.start, selection.end, '');
      widget.controller.text = newText;
      widget.controller.selection =
          TextSelection.collapsed(offset: selection.start);
      widget.onTextChanged?.call(newText);
    } else {
      final cursorPos = selection.isValid ? selection.baseOffset : text.length;
      if (cursorPos > 0) {
        final newText =
            text.substring(0, cursorPos - 1) + text.substring(cursorPos);
        widget.controller.text = newText;
        widget.controller.selection =
            TextSelection.collapsed(offset: cursorPos - 1);
        widget.onTextChanged?.call(newText);
      }
    }
  }

  void _startBackspaceRepeat() {
    _onBackspace();
    _backspaceTimer = Timer(const Duration(milliseconds: 400), () {
      _backspaceTimer = Timer.periodic(
        const Duration(milliseconds: 60),
        (_) => _onBackspace(),
      );
    });
  }

  void _stopBackspaceRepeat() {
    _backspaceTimer?.cancel();
    _backspaceTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _showSymbols ? _symbolRows : _letterRows;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final uiScale = context.watch<SettingsProvider>().uiScale;
    // Cap key size so keyboard never exceeds ~40% of screen height
    // and keys stay a reasonable touch-target size.
    // Scale the max bounds with UI scale so keys grow/shrink with the setting.
    // On wider screens (>1200px), allow keys to grow larger for easier touch targets
    final isWideScreen = screenWidth > 1200;
    final maxW = (52.0 * uiScale).clamp(32.0, isWideScreen ? 80.0 : 64.0);
    final maxH = ((screenHeight * 0.40 - 52) / 4.0).clamp(32.0, (46.0 * uiScale).clamp(32.0, isWideScreen ? 64.0 : 56.0));
    final rawKeyWidth = (screenWidth - 32 - 10 * 4) / 10; // account for padding between keys
    final keyWidth = rawKeyWidth.clamp(32.0, maxW);
    final keyHeight = keyWidth.clamp(32.0, maxH);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1528),
        border: Border(
          top: BorderSide(color: AppTheme.textSecondary.withOpacity(0.2)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(rows[0], keyWidth, keyHeight),
          const SizedBox(height: 4),
          _buildRow(rows[1], keyWidth, keyHeight),
          const SizedBox(height: 4),
          _buildRow3(rows[2], keyWidth, keyHeight),
          const SizedBox(height: 4),
          _buildBottomRow(keyWidth, keyHeight),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, double keyWidth, double keyHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((k) {
        final display = _shifted || _showSymbols ? k : k.toLowerCase();
        return _KeyButton(
          label: display,
          width: keyWidth,
          height: keyHeight,
          onTap: () => _onKey(display),
        );
      }).toList(),
    );
  }

  Widget _buildRow3(List<String> keys, double keyWidth, double keyHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shift key
        if (!_showSymbols)
          _KeyButton(
            icon: _shifted ? Icons.keyboard_capslock : Icons.keyboard_arrow_up,
            width: keyWidth * 1.5,
            height: keyHeight,
            color: _shifted ? AppTheme.accentGold.withOpacity(0.3) : null,
            iconColor: _shifted ? AppTheme.accentGold : null,
            onTap: () => setState(() => _shifted = !_shifted),
          ),
        ...keys.map((k) {
          final display = _shifted || _showSymbols ? k : k.toLowerCase();
          return _KeyButton(
            label: display,
            width: keyWidth,
            height: keyHeight,
            onTap: () => _onKey(display),
          );
        }),
        // Backspace with hold-to-repeat
        _KeyButton(
          icon: Icons.backspace_outlined,
          width: keyWidth * 1.5,
          height: keyHeight,
          onTapDown: _startBackspaceRepeat,
          onTapUp: _stopBackspaceRepeat,
          onTapCancel: _stopBackspaceRepeat,
        ),
      ],
    );
  }

  Widget _buildBottomRow(double keyWidth, double keyHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Symbol toggle
        _KeyButton(
          label: _showSymbols ? 'ABC' : '?123',
          width: keyWidth * 1.5,
          height: keyHeight,
          fontSize: 14,
          onTap: () => setState(() {
            _showSymbols = !_showSymbols;
            if (!_showSymbols) _shifted = false;
          }),
        ),
        // Space bar
        _KeyButton(
          label: '',
          icon: Icons.space_bar,
          width: keyWidth * 5,
          height: keyHeight,
          onTap: () => _onKey(' '),
        ),
        // Period (quick access)
        _KeyButton(
          label: '.',
          width: keyWidth,
          height: keyHeight,
          onTap: () => _onKey('.'),
        ),
        // Done
        _KeyButton(
          label: 'Done',
          width: keyWidth * 2,
          height: keyHeight,
          color: AppTheme.accentGold,
          textColor: AppTheme.primaryDark,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          onTap: widget.onDone,
        ),
      ],
    );
  }
}

/// Individual key button with press animation and visual feedback.
class _KeyButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final double width;
  final double height;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final VoidCallback? onTapCancel;

  const _KeyButton({
    this.label,
    this.icon,
    required this.width,
    required this.height,
    this.color,
    this.textColor,
    this.iconColor,
    this.fontSize,
    this.fontWeight,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? AppTheme.cardDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          widget.onTapDown?.call();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTapUp?.call();
          if (widget.onTapDown == null) {
            widget.onTap?.call();
          }
        },
        onTapCancel: () {
          setState(() => _pressed = false);
          widget.onTapCancel?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _pressed
                ? (widget.color ?? AppTheme.accentGold).withOpacity(0.5)
                : bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _pressed
                  ? AppTheme.accentGold.withOpacity(0.6)
                  : AppTheme.textSecondary.withOpacity(0.15),
              width: _pressed ? 1.5 : 1,
            ),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 1,
                    ),
                  ],
          ),
          child: Center(
            child: widget.icon != null && (widget.label == null || widget.label!.isEmpty)
                ? Icon(
                    widget.icon,
                    size: (widget.height * 0.4).clamp(14.0, 20.0),
                    color: widget.iconColor ??
                        widget.textColor ??
                        AppTheme.textPrimary,
                  )
                : Text(
                    widget.label ?? '',
                    style: TextStyle(
                      fontSize: widget.fontSize ?? (widget.height * 0.38).clamp(12.0, 18.0),
                      fontWeight: widget.fontWeight ?? FontWeight.w500,
                      color: widget.textColor ?? AppTheme.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A helper widget that wraps a TextField with an optional on-screen keyboard.
/// Tapping the keyboard icon toggles the keyboard below the field.
class TouchKeyboardField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;

  const TouchKeyboardField({
    super.key,
    required this.controller,
    this.decoration,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
  });

  @override
  State<TouchKeyboardField> createState() => _TouchKeyboardFieldState();
}

class _TouchKeyboardFieldState extends State<TouchKeyboardField> {
  bool _showKeyboard = false;
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _lastInteractionWasTouch = false;
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final currentText = widget.controller.text;
    if (currentText != _lastText) {
      _lastText = currentText;
      widget.onChanged?.call(currentText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleKeyboard() {
    setState(() {
      _showKeyboard = !_showKeyboard;
      if (_showKeyboard) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _hideKeyboard() {
    if (!_showKeyboard) return;
    setState(() => _showKeyboard = false);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Material(
          elevation: 8,
          child: TouchKeyboard(
            controller: widget.controller,
            focusNode: _focusNode,
            onTextChanged: (text) {
              widget.onChanged?.call(text);
            },
            onDone: () {
              _hideKeyboard();
              widget.onSubmitted?.call(widget.controller.text);
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final baseDecoration = widget.decoration ?? const InputDecoration();
    final decoration = baseDecoration.copyWith(
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (baseDecoration.suffixIcon != null) baseDecoration.suffixIcon!,
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: Icon(
                _showKeyboard ? Icons.keyboard_hide : Icons.keyboard,
                color: _showKeyboard
                    ? AppTheme.accentGold
                    : AppTheme.textSecondary,
                size: 24,
              ),
              onPressed: _toggleKeyboard,
              tooltip: _showKeyboard ? 'Hide keyboard' : 'Show keyboard',
            ),
          ),
        ],
      ),
    );

    return Listener(
      onPointerDown: (event) {
        _lastInteractionWasTouch = event.kind == PointerDeviceKind.touch;
      },
      child: GestureDetector(
        onDoubleTap: () {
          // Select the word at the current cursor position
          final text = widget.controller.text;
          final offset = widget.controller.selection.baseOffset.clamp(0, text.length);
          if (text.isNotEmpty) {
            // Find word boundaries around the cursor
            int start = offset;
            int end = offset;
            while (start > 0 && text[start - 1] != ' ') {
              start--;
            }
            while (end < text.length && text[end] != ' ') {
              end++;
            }
            if (start != end) {
              widget.controller.selection = TextSelection(
                baseOffset: start,
                extentOffset: end,
              );
            }
          }
          // Also open the touch keyboard if it was a finger double-tap
          if (_lastInteractionWasTouch && !_showKeyboard) {
            _toggleKeyboard();
          }
          _focusNode.requestFocus();
        },
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: decoration,
          textCapitalization: widget.textCapitalization,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          textInputAction: widget.onSubmitted != null
              ? TextInputAction.search
              : TextInputAction.done,
          maxLines: widget.maxLines,
          readOnly: _showKeyboard,
          showCursor: true,
          enableInteractiveSelection: true,
          onTap: () {
            if (_lastInteractionWasTouch && !_showKeyboard) {
              _toggleKeyboard();
            } else if (_showKeyboard) {
              _focusNode.requestFocus();
            }
          },
        ),
      ),
    );
  }
}
