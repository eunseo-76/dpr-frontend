class FieldConfig {
  final String key;
  final String label;
  final bool required;
  final int? maxLength;

  const FieldConfig({
    required this.key,
    required this.label,
    this.required = false,
    this.maxLength,
  });
}