import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../theme/app_theme.dart';
import 'touch_keyboard.dart';

/// A touch-friendly search bar for filtering games by title.
class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TouchKeyboardField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search games...',
        prefixIcon: const Icon(Icons.search, size: 26),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: Icon(
              Icons.clear,
              size: 24,
              color: _controller.text.isNotEmpty
                  ? null
                  : AppTheme.textSecondary.withOpacity(0.3),
            ),
            onPressed: _controller.text.isNotEmpty
                ? () {
                    _controller.clear();
                    context.read<GameProvider>().setSearchQuery('');
                    setState(() {});
                  }
                : null,
          ),
        ),
      ),
      onChanged: (value) {
        context.read<GameProvider>().setSearchQuery(value);
        setState(() {}); // Refresh clear button visibility
      },
    );
  }
}
