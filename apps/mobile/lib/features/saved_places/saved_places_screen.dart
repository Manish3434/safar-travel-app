import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import 'providers/saved_places_provider.dart';

class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final savedPlaces = ref.watch(savedPlacesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.savedPlaces ?? 'Saved Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: l10n?.offlineMaps ?? 'Offline Maps',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.offlineMaps);
            },
          ),
        ],
      ),
      body: savedPlaces.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 64,
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.noSavedPlaces ?? 'No saved places yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save destinations to access details and routes anytime, even when offline.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafarColors.saffron,
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
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              itemCount: savedPlaces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final place = savedPlaces[index];
                final locale = Localizations.localeOf(context).languageCode;
                final displayName = locale == 'ta' && place.nameTa != null
                    ? place.nameTa!
                    : (locale == 'hi' && place.nameHi != null ? place.nameHi! : place.name);

                return Dismissible(
                  key: Key(place.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                  ),
                  onDismissed: (_) {
                    HapticFeedback.mediumImpact();
                    ref.read(savedPlacesProvider.notifier).toggleSave(place);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${place.name} from saved'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref.read(savedPlacesProvider.notifier).toggleSave(place);
                          },
                        ),
                      ),
                    );
                  },
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.placeDetailPath(place.id));
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? SafarColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: place.mainPhotoUrl != null
                                  ? Image.network(
                                      place.mainPhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: isDark ? SafarColors.darkSurface : Colors.grey.shade200,
                                        child: const Icon(Icons.landscape, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      color: isDark ? SafarColors.darkSurface : Colors.grey.shade200,
                                      child: const Icon(Icons.landscape, color: Colors.grey),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
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
                                        color: SafarColors.teal.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        place.category.toUpperCase(),
                                        style: const TextStyle(
                                          color: SafarColors.teal,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    if (place.rating != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star_rounded, size: 14, color: SafarColors.saffron),
                                      const SizedBox(width: 2),
                                      Text(
                                        place.rating!.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_remove_outlined, color: Colors.grey),
                            tooltip: 'Remove',
                            onPressed: () {
                              ref.read(savedPlacesProvider.notifier).toggleSave(place);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
