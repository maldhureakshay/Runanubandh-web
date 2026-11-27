import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/picker_group.dart';

/// Searchable grouped picker (admin web dialog; mirrors mobile `SearchablePickerSheet`).
class SearchablePickerDialog extends StatefulWidget {
  const SearchablePickerDialog({
    super.key,
    required this.title,
    required this.groups,
    this.currentValue,
  });

  final String title;
  final List<PickerGroup> groups;
  final String? currentValue;

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<PickerGroup> groups,
    String? currentValue,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SearchablePickerDialog(
        title: title,
        groups: groups,
        currentValue: currentValue,
      ),
    );
  }

  @override
  State<SearchablePickerDialog> createState() => _SearchablePickerDialogState();
}

class _SearchablePickerDialogState extends State<SearchablePickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PickerGroup> get _filtered {
    if (_query.isEmpty) return widget.groups;
    final result = <PickerGroup>[];
    for (final g in widget.groups) {
      final matched = g.items
          .where((item) => item.toLowerCase().contains(_query))
          .toList();
      if (matched.isNotEmpty) {
        result.add(PickerGroup(label: g.label, items: matched));
      }
    }
    return result;
  }

  void _pick(String value) => Navigator.of(context).pop(value);

  Future<void> _enterOwn() async {
    final isCustom = widget.currentValue != null &&
        !widget.groups.any((g) => g.items.contains(widget.currentValue));
    final initial = isCustom ? widget.currentValue : '';
    final custom = await showDialog<String>(
      context: context,
      builder: (ctx) => _CustomValueDialog(initialValue: initial),
    );
    if (custom != null && custom.trim().isNotEmpty && mounted) {
      _pick(custom.trim());
    }
  }

  int _itemCount(List<PickerGroup> groups) =>
      groups.fold(0, (sum, g) => sum + 1 + g.items.length);

  Widget _buildItem(BuildContext context, int index, List<PickerGroup> groups) {
    var cursor = 0;
    for (final group in groups) {
      if (index == cursor) return _GroupHeader(label: group.label);
      cursor++;
      for (final item in group.items) {
        if (index == cursor) {
          return _PickerTile(
            value: item,
            isSelected: item == widget.currentValue,
            query: _query,
            onTap: () => _pick(item),
          );
        }
        cursor++;
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: 480,
        height: maxH.clamp(320.0, 640.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _search.clear,
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            _EnterOwnTile(
              isSelected: widget.currentValue != null &&
                  !widget.groups
                      .any((g) => g.items.contains(widget.currentValue)),
              onTap: _enterOwn,
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      query: _search.text.trim(),
                      onUseCustom: () {
                        final q = _search.text.trim();
                        if (q.isNotEmpty) _pick(q);
                      },
                    )
                  : ListView.builder(
                      itemCount: _itemCount(filtered),
                      itemBuilder: (ctx, i) => _buildItem(ctx, i, filtered),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _CustomValueDialog extends StatefulWidget {
  const _CustomValueDialog({this.initialValue});

  final String? initialValue;

  @override
  State<_CustomValueDialog> createState() => _CustomValueDialogState();
}

class _CustomValueDialogState extends State<_CustomValueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter your own value'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Type education or occupation',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('OK'),
        ),
      ],
    );
  }

  void _save() {
    final v = _controller.text.trim();
    if (v.isEmpty) return;
    Navigator.pop(context, v);
  }
}

class _EnterOwnTile extends StatelessWidget {
  const _EnterOwnTile({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your own value',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Can't find yours in the list? Type it yourself.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  size: 18, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '--$label--',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.value,
    required this.isSelected,
    required this.query,
    required this.onTap,
  });

  final String value;
  final bool isSelected;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: isSelected,
      title: _highlightedText(context),
      trailing: isSelected
          ? const Icon(Icons.check_circle,
              size: 18, color: AppTheme.primaryColor)
          : null,
      onTap: onTap,
    );
  }

  Widget _highlightedText(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      );
    }

    final lower = value.toLowerCase();
    final start = lower.indexOf(query);
    if (start == -1) return Text(value, maxLines: 2, overflow: TextOverflow.ellipsis);

    final end = start + query.length;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          if (start > 0) TextSpan(text: value.substring(0, start)),
          TextSpan(
            text: value.substring(start, end),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (end < value.length) TextSpan(text: value.substring(end)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onUseCustom});

  final String query;
  final VoidCallback onUseCustom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'No options' : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onUseCustom,
                child: Text('Use "$query" as custom value'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
