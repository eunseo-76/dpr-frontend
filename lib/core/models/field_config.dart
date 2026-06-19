class FieldConfig {
  final String key;
  final String label;
  final bool required;

  const FieldConfig({
    required this.key,
    required this.label,
    this.required = false,
  });
}