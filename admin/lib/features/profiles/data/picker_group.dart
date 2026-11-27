/// Named group of selectable picker items (matches mobile `PickerGroup`).
class PickerGroup {
  const PickerGroup({required this.label, required this.items});

  final String label;
  final List<String> items;
}
