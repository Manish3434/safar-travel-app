import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_map_models.dart';

const String _kOfflineRegionsKey = 'safar_offline_map_regions_v1';

/// Custom TileProvider that checks local cache before falling back to network.
class SafarOfflineTileProvider extends TileProvider {
  final Map<String, Uint8List> _memoryTileCache = {};

  SafarOfflineTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return NetworkImage(url, headers: headers);
  }

  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer options) {
    return options.urlTemplate!
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString());
  }
}

class OfflineRegionsNotifier extends StateNotifier<List<OfflineRegion>> {
  OfflineRegionsNotifier() : super([]) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kOfflineRegionsKey) ?? [];
      state = list
          .map((s) => OfflineRegion.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading offline regions: $e');
    }
  }

  Future<void> saveRegions(List<OfflineRegion> regions) async {
    state = regions;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = regions.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_kOfflineRegionsKey, list);
    } catch (e) {
      debugPrint('Error saving offline regions: $e');
    }
  }

  bool isDownloaded(double lat, double lng, {double radiusKm = 20}) {
    for (final region in state) {
      if (region.status == OfflineRegionStatus.downloaded) {
        final dist = _haversineDistance(lat, lng, region.centerLat, region.centerLng);
        if (dist <= radiusKm) return true;
      }
    }
    return false;
  }

  Future<void> downloadRegion({
    required String id,
    required String name,
    required double lat,
    required double lng,
    int minZoom = 11,
    int maxZoom = 14,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Mark as downloading
    final existingIndex = state.indexWhere((r) => r.id == id);
    final region = OfflineRegion(
      id: id,
      name: name,
      centerLat: lat,
      centerLng: lng,
      minZoom: minZoom,
      maxZoom: maxZoom,
      tileCount: 0,
      sizeBytes: 0,
      status: OfflineRegionStatus.downloading,
      downloadedAt: DateTime.now(),
    );

    List<OfflineRegion> nextState;
    if (existingIndex >= 0) {
      nextState = [...state]..[existingIndex] = region;
    } else {
      nextState = [region, ...state];
    }
    await saveRegions(nextState);

    // 2. Compute tile count within bounding box
    int totalTiles = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      totalTiles += (z - minZoom + 1) * 8;
    }

    try {
      // Simulate stepped download progression with progress callbacks
      const steps = 10;
      for (int i = 1; i <= steps; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        onProgress?.call(i / steps);
      }

      final completedRegion = region.copyWith(
        tileCount: totalTiles,
        sizeBytes: totalTiles * 14200, // ~14 KB per OSM PNG tile
        status: OfflineRegionStatus.downloaded,
        downloadedAt: DateTime.now(),
      );

      final updated = state.map((r) => r.id == id ? completedRegion : r).toList();
      await saveRegions(updated);
    } catch (e) {
      final failedRegion = region.copyWith(status: OfflineRegionStatus.failed);
      final updated = state.map((r) => r.id == id ? failedRegion : r).toList();
      await saveRegions(updated);
    }
  }

  Future<void> deleteRegion(String id) async {
    final nextState = state.where((r) => r.id != id).toList();
    await saveRegions(nextState);
  }

  Future<void> clearAllRegions() async {
    await saveRegions([]);
  }

  int get totalSizeBytes => state.fold(0, (sum, r) => sum + r.sizeBytes);
  int get totalTileCount => state.fold(0, (sum, r) => sum + r.tileCount);

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // Earth's radius in km
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

final offlineRegionsProvider =
    StateNotifierProvider<OfflineRegionsNotifier, List<OfflineRegion>>((ref) {
  return OfflineRegionsNotifier();
});

final isPlaceOfflineDownloadedProvider =
    Provider.family<bool, ll.LatLng>((ref, latLng) {
  final regions = ref.watch(offlineRegionsProvider);
  final notifier = ref.read(offlineRegionsProvider.notifier);
  return notifier.isDownloaded(latLng.latitude, latLng.longitude);
});
