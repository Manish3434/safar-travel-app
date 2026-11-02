import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/offline/offline_map_models.dart';
import '../../core/offline/offline_map_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class OfflineMapsScreen extends ConsumerWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final regions = ref.watch(offlineRegionsProvider);
    final notifier = ref.read(offlineRegionsProvider.notifier);

    final totalBytes = notifier.totalSizeBytes;
    final totalTiles = notifier.totalTileCount;
    final formattedTotalSize = _formatBytes(totalBytes);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.offlineMaps ?? 'Offline Maps'),
        actions: [
          if (regions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n?.clearAllMaps ?? 'Clear All Maps',
              onPressed: () => _confirmClearAll(context, ref, l10n),
            ),
        ],
      ),
      body: regions.isEmpty
          ? _EmptyOfflineMapsView(l10n: l10n, isDark: isDark, theme: theme)
          : ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                // ── Storage Overview Card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [SafarColors.darkCard, SafarColors.darkSurface]
                          : [SafarColors.tealDark, SafarColors.teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: SafarColors.teal.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sd_storage_outlined, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.storageUsed ?? 'Storage Used',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${regions.length} ${regions.length == 1 ? "Region" : "Regions"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formattedTotalSize,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '•  $totalTiles cached tiles',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stored securely on device for zero-connectivity exploration.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Section Title ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    l10n?.downloadedMaps ?? 'Downloaded Maps',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Regions List ──────────────────────────────────────────
                ...regions.map((region) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RegionCard(
                      region: region,
                      isDark: isDark,
                      theme: theme,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go(AppRoutes.placeDetailPath(region.id));
                      },
                      onDelete: () {
                        HapticFeedback.mediumImpact();
                        ref.read(offlineRegionsProvider.notifier).deleteRegion(region.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${region.name} offline map removed'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref, AppLocalizations? l10n) {
    HapticFeedback.selectionClick();
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.clearAllMaps ?? 'Clear All Maps'),
        content: Text(
          l10n?.clearAllConfirm ??
              'Are you sure you want to delete all downloaded offline maps? You will need internet to load them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              HapticFeedback.heavyImpact();
              ref.read(offlineRegionsProvider.notifier).clearAllRegions();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All offline maps cleared')),
              );
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _RegionCard extends StatelessWidget {
  final OfflineRegion region;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RegionCard({
    required this.region,
    required this.isDark,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = region.status == OfflineRegionStatus.downloaded
        ? Colors.green.shade600
        : (region.status == OfflineRegionStatus.downloading
            ? SafarColors.saffron
            : Colors.red.shade500);

    final statusLabel = region.status == OfflineRegionStatus.downloaded
        ? 'Offline Ready'
        : (region.status == OfflineRegionStatus.downloading
            ? 'Downloading...'
            : 'Download Failed');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? SafarColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Map preview icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: SafarColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: SafarColors.teal,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Region details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              region.status == OfflineRegionStatus.downloaded
                                  ? Icons.check_circle_outline
                                  : Icons.sync,
                              size: 11,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${region.formattedSize}  (${region.tileCount} tiles)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zoom ${region.minZoom}–${region.maxZoom} • ${_formatDate(region.downloadedAt)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Action delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
              tooltip: 'Delete Map',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _EmptyOfflineMapsView extends StatelessWidget {
  final AppLocalizations? l10n;
  final bool isDark;
  final ThemeData theme;

  const _EmptyOfflineMapsView({
    required this.l10n,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_for_offline_outlined,
                size: 64,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n?.noOfflineMaps ?? 'No offline maps downloaded',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n?.downloadMapHint ??
                  'Download regional map tiles from any place page for seamless offline navigation without internet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SafarColors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.home);
              },
              icon: const Icon(Icons.explore_outlined),
              label: Text(l10n?.explorePlaces ?? 'Explore Places'),
            ),
          ],
        ),
      ),
    );
  }
}
