import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Tappable field that opens [onTap] (e.g. searchable picker dialog).
class SearchableValueField extends StatelessWidget {
  const SearchableValueField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint = 'Tap to select',
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final display = value?.trim();
    final hasValue = display != null && display.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.unfold_more),
        ),
        child: Text(
          hasValue ? display : hint,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasValue
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}
