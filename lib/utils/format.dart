/// Human-readable byte sizes for download progress (e.g. "842.3 MB").
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final exp = (bytes / 1024).floor().clamp(0, units.length - 1);
  final value = bytes / (1 << (exp * 10));
  final pretty =
      exp == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$pretty ${units[exp]}';
}