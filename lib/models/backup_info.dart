
class BackupInfo {
  final String timestamp;
  final String time;
  final String path;
  final int size;
  final bool encrypted;
  final bool manual;

  BackupInfo({
    required this.timestamp,
    required this.time,
    required this.path,
    required this.size,
    required this.encrypted,
    required this.manual,
  });

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      timestamp: json['timestamp'] ?? '',
      time: json['time'] ?? '',
      path: json['path'] ?? '',
      size: json['size'] ?? 0,
      encrypted: json['encrypted'] ?? false,
      manual: json['manual'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'time': time,
      'path': path,
      'size': size,
      'encrypted': encrypted,
      'manual': manual,
    };
  }

  
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
