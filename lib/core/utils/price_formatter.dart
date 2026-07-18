String formatETB(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (value.toUpperCase().startsWith('ETB')) return value;
  if (value.startsWith(r'$')) {
    final numeric = value.substring(1).trim();
    return numeric.isEmpty ? 'ETB' : 'ETB $numeric';
  }
  final sanitized = value.replaceAll(RegExp(r'[^0-9,\.]'), '').trim();
  return sanitized.isEmpty ? value : 'ETB $sanitized';
}
