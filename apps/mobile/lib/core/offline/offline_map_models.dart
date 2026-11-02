import 'package:flutter/foundation.dart';

enum OfflineRegionStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

@immutable
class OfflineRegion {
  final String id;
  final String name;
  final double centerLat;
  final double centerLng;
  final int minZoom;
  final int maxZoom;
  final int tileCount;
  final int sizeBytes;
  final OfflineRegionStatus status;
  final DateTime downloadedAt;

  const OfflineRegion({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
    required this.sizeBytes,
    required this.status,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'centerLat': centerLat,
        'centerLng': centerLng,
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'tileCount': tileCount,
        'sizeBytes': sizeBytes,
        'status': status.name,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory OfflineRegion.fromJson(Map<String, dynamic> json) {
    return OfflineRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      centerLat: (json['centerLat'] as num).toDouble(),
      centerLng: (json['centerLng'] as num).toDouble(),
      minZoom: json['minZoom'] as int? ?? 11,
      maxZoom: json['maxZoom'] as int? ?? 14,
      tileCount: json['tileCount'] as int? ?? 0,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      status: OfflineRegionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OfflineRegionStatus.notDownloaded,
      ),
      downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  OfflineRegion copyWith({
    String? id,
    String? name,
    double? centerLat,
    double? centerLng,
    int? minZoom,
    int? maxZoom,
    int? tileCount,
    int? sizeBytes,
    OfflineRegionStatus? status,
    DateTime? downloadedAt,
  }) {
    return OfflineRegion(
      id: id ?? this.id,
      name: name ?? this.name,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      tileCount: tileCount ?? this.tileCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
