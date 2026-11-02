import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/error/failures.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/rope_scrollbar.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import '../../core/offline/offline_map_models.dart';
import '../../core/offline/offline_map_service.dart';
import '../search/models/place_models.dart';
import '../search/providers/search_provider.dart';
import '../saved_places/providers/saved_places_provider.dart';
import 'providers/place_detail_providers.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  String _selectedFromCity = 'Chennai';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final placeAsync = ref.watch(placeDetailProvider(widget.placeId));
    final savedPlaces = ref.watch(savedPlacesProvider);
    final isSaved = savedPlaces.any((p) => p.id == widget.placeId);

    return Scaffold(
      body: placeAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(leading: const BackButton()),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DetailSectionSkeleton(isDark: isDark, height: 200),
                const SizedBox(height: 16),
                DetailSectionSkeleton(isDark: isDark, height: 80),
                const SizedBox(height: 16),
                DetailSectionSkeleton(isDark: isDark, height: 120),
              ],
            ),
          ),
        ),
        error: (err, _) => _buildErrorScreen(err.toString(), theme, l10n),
        data: (result) => result.when(
          failure: (failure) => _buildFailureScreen(failure, theme, l10n),
          success: (place) {
            final locale = Localizations.localeOf(context).languageCode;
            final displayName = locale == 'ta' && place.nameTa != null
                ? place.nameTa!
                : (locale == 'hi' && place.nameHi != null ? place.nameHi! : place.name);

            final photos = place.photos.isNotEmpty
                ? place.photos
                : (place.mainPhotoUrl != null ? [place.mainPhotoUrl!] : <String>[]);

            return RopeScrollbar(
              child: RefreshIndicator(
                onRefresh: () async {
                  await HapticFeedback.mediumImpact();
                  ref.invalidate(placeWeatherProvider(widget.placeId));
                  ref.invalidate(placeStaysProvider(widget.placeId));
                  ref.invalidate(placeDetailProvider(widget.placeId));
                  await ref.read(placeDetailProvider(widget.placeId).future);
                },
                child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  // ── Hero photo header & AppBar ─────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.4),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    actions: [
                      CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.4),
                        child: IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                            color: isSaved ? SafarColors.saffron : Colors.white,
                          ),
                          tooltip: isSaved ? (l10n?.saved ?? 'Saved') : (l10n?.savePlace ?? 'Save'),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            ref.read(savedPlacesProvider.notifier).toggleSave(place);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isSaved
                                    ? 'Removed from saved places'
                                    : 'Saved to your offline places!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: photos.isNotEmpty
                          ? Image.network(
                              photos.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: SafarColors.darkSurface,
                                child: const Icon(Icons.landscape, size: 64, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: SafarColors.darkSurface,
                              child: const Icon(Icons.landscape, size: 64, color: Colors.grey),
                            ),
                    ),
                  ),

                  // ── Body Content ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: SafarColors.teal.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            place.category.toUpperCase(),
                                            style: const TextStyle(
                                              color: SafarColors.teal,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Source: ${place.source}',
                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (place.rating != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: SafarColors.saffron.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: SafarColors.saffronDark, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        place.rating!.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: SafarColors.saffronDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Sensitive Spot Warning (Rule 8)
                          if (place.sensitive)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shield_outlined, color: Colors.amber.shade800),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      l10n?.sensitiveSpotWarning ??
                                          'Sensitive ecological area. Coordinates shown are approximate to protect local wildlife.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Quick Specs Grid
                          _buildQuickSpecs(place, l10n, isDark),
                          const SizedBox(height: 20),

                          // Description
                          Text(place.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                          const SizedBox(height: 20),

                          // Navigation Action Button (Line 64 of Project Brief)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: SafarColors.teal),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening Navigation to (${place.location.lat}, ${place.location.lng})...'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.directions_rounded, color: SafarColors.teal),
                              label: const Text(
                                'Turn-by-Turn Navigation',
                                style: TextStyle(fontWeight: FontWeight.bold, color: SafarColors.teal),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // How to reach
                          if (place.howToReach != null) ...[
                            _SectionHeader(title: l10n?.howToReach ?? 'How to Reach', icon: Icons.navigation_rounded),
                            const SizedBox(height: 8),
                            Text(place.howToReach!, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 24),
                          ],

                          // Interactive OpenStreetMap Preview
                          _SectionHeader(title: l10n?.viewOnMap ?? 'Location & Map', icon: Icons.map_rounded),
                          const SizedBox(height: 8),
                          _PlaceMapPreview(place: place, isDark: isDark),
                          const SizedBox(height: 24),

                          // Weather Widget
                          _SectionHeader(title: l10n?.weather ?? 'Weather', icon: Icons.wb_sunny_rounded),
                          const SizedBox(height: 8),
                          _WeatherWidget(placeId: place.id, isDark: isDark),
                          const SizedBox(height: 24),

                          // Stays Widget
                          _SectionHeader(title: l10n?.stays ?? 'Nearby Stays', icon: Icons.hotel_rounded),
                          const SizedBox(height: 8),
                          _StaysWidget(placeId: place.id, isDark: isDark, l10n: l10n),
                          const SizedBox(height: 24),

                          // Transport & Bus Timings Widget
                          _SectionHeader(title: l10n?.transport ?? 'Transport & Bus Timings', icon: Icons.directions_bus_rounded),
                          const SizedBox(height: 8),
                          _TransportWidget(
                            destinationName: place.name,
                            selectedFromCity: _selectedFromCity,
                            onCityChanged: (city) => setState(() => _selectedFromCity = city),
                            isDark: isDark,
                            l10n: l10n,
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildQuickSpecs(PlaceDetail place, AppLocalizations? l10n, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? SafarColors.darkCard : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SpecItem(
                  icon: Icons.calendar_today_rounded,
                  label: l10n?.bestSeason ?? 'Best Season',
                  value: place.bestSeason ?? 'Year round',
                ),
              ),
              Expanded(
                child: _SpecItem(
                  icon: Icons.verified_user_outlined,
                  label: l10n?.permitRequired ?? 'Permit',
                  value: place.permitRequired ? 'Required' : 'Not required',
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: _SpecItem(
                  icon: Icons.person_pin_circle_outlined,
                  label: l10n?.guideRequired ?? 'Guide',
                  value: place.guideRequired ? 'Recommended' : 'Optional',
                ),
              ),
              Expanded(
                child: _SpecItem(
                  icon: Icons.network_cell_rounded,
                  label: 'Network',
                  value: place.networkInfo ?? 'Available',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailureScreen(AppFailure failure, ThemeData theme, AppLocalizations? l10n) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                failure is NotFoundFailure ? Icons.search_off_rounded : Icons.cloud_off_rounded,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                failure.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(placeDetailProvider(widget.placeId)),
                child: Text(l10n?.retry ?? 'Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error, ThemeData theme, AppLocalizations? l10n) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(l10n?.errorLoading ?? 'Failed to load details'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.refresh(placeDetailProvider(widget.placeId)),
              child: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: SafarColors.teal),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: SafarColors.saffron),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherWidget extends ConsumerWidget {
  final String placeId;
  final bool isDark;

  const _WeatherWidget({required this.placeId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(placeWeatherProvider(placeId));

    return weatherAsync.when(
      loading: () => DetailSectionSkeleton(isDark: isDark, height: 110),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? SafarColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Text(
              'Weather data unavailable offline',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ],
        ),
      ),
      data: (result) => result.when(
        failure: (f) => Text(f.message, style: const TextStyle(color: Colors.grey)),
        success: (weather) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? SafarColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperatureC.round()}°C',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          weather.condition,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: SafarColors.teal),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Humidity: ${weather.humidityPct}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('Wind: ${weather.windKmh.round()} km/h', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                if (weather.forecast.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: weather.forecast.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final day = weather.forecast[idx];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? SafarColors.darkSurface : SafarColors.offWhite,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.date.length >= 5 ? day.date.substring(5) : day.date,
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                '${day.maxC.round()}°',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StaysWidget extends ConsumerWidget {
  final String placeId;
  final bool isDark;
  final AppLocalizations? l10n;

  const _StaysWidget({required this.placeId, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staysAsync = ref.watch(placeStaysProvider(placeId));

    return staysAsync.when(
      loading: () => DetailSectionSkeleton(isDark: isDark, height: 120),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? SafarColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.hotel_outlined, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Text(
              'Stays data unavailable offline',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ],
        ),
      ),
      data: (result) => result.when(
        failure: (f) => Text(f.message, style: const TextStyle(color: Colors.grey)),
        success: (stays) {
          if (stays.isEmpty) {
            return const Text('No stays listed near this spot yet');
          }

          return Column(
            children: stays.map((stay) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? SafarColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: SafarColors.teal.withOpacity(0.12),
                      child: const Icon(Icons.hotel, color: SafarColors.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stay.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${stay.type.toUpperCase()} · ${stay.distanceKm} km away',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${stay.pricePerNightInr}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: SafarColors.saffronDark,
                          ),
                        ),
                        Text(l10n?.perNight ?? 'per night', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TransportWidget extends ConsumerWidget {
  final String destinationName;
  final String selectedFromCity;
  final ValueChanged<String> onCityChanged;
  final bool isDark;
  final AppLocalizations? l10n;

  const _TransportWidget({
    required this.destinationName,
    required this.selectedFromCity,
    required this.onCityChanged,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = RouteQuery(from: selectedFromCity, to: destinationName);
    final transportAsync = ref.watch(placeTransportProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // From selector
        Row(
          children: [
            const Text('From:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedFromCity,
              underline: const SizedBox(),
              items: const ['Chennai', 'Bangalore', 'Mumbai', 'Pune', 'Coimbatore'].map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  HapticFeedback.selectionClick();
                  onCityChanged(val);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        transportAsync.when(
          loading: () => DetailSectionSkeleton(isDark: isDark, height: 80),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? SafarColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_bus_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Transport schedules unavailable offline',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
              ],
            ),
          ),
          data: (resultState) => resultState.when(
            failure: (f) => Text(f.message, style: const TextStyle(color: Colors.grey)),
            success: (result) {
              if (!result.available || result.trips.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? SafarColors.darkCard : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    result.reason ?? 'Direct bus schedule not available. Check local junction bus stands.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: result.trips.map((trip) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? SafarColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus, color: SafarColors.teal, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trip.operator} (${trip.busType})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${trip.departsAt} → ${trip.arrivesAt}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${trip.fareInr}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'Updated ${trip.lastUpdated.split("T").first}',
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlaceMapPreview extends ConsumerStatefulWidget {
  final PlaceDetail place;
  final bool isDark;

  const _PlaceMapPreview({required this.place, required this.isDark});

  @override
  ConsumerState<_PlaceMapPreview> createState() => _PlaceMapPreviewState();
}

class _PlaceMapPreviewState extends ConsumerState<_PlaceMapPreview> {
  late final MapController _mapController;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _handleDownloadRegion(ll.LatLng latLng, String regionId, String name) async {
    await HapticFeedback.mediumImpact();
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final notifier = ref.read(offlineRegionsProvider.notifier);
    await notifier.downloadRegion(
      id: regionId,
      name: name,
      lat: latLng.latitude,
      lng: latLng.longitude,
      minZoom: 11,
      maxZoom: 14,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offline map saved for $name (~1.2 MB)'),
          backgroundColor: SafarColors.teal,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final latLng = ll.LatLng(place.location.lat, place.location.lng);
    final regionId = 'reg_${place.districtId ?? place.id}';
    final regions = ref.watch(offlineRegionsProvider);
    final isDownloaded = regions.any(
      (r) => r.id == regionId && r.status == OfflineRegionStatus.downloaded,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: latLng,
                initialZoom: 12.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'in.safar.app',
                  tileProvider: SafarOfflineTileProvider(),
                ),
                if (place.sensitive)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: latLng,
                        radius: 2000,
                        useRadiusInMeter: true,
                        color: Colors.amber.withOpacity(0.25),
                        borderColor: Colors.amber.shade800,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  )
                else
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLng,
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: SafarColors.saffron,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Map controls overlay (Zoom in / out)
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_in',
                    backgroundColor: widget.isDark ? SafarColors.darkCard : Colors.white,
                    foregroundColor: SafarColors.teal,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(latLng, zoom + 1);
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'map_zoom_out',
                    backgroundColor: widget.isDark ? SafarColors.darkCard : Colors.white,
                    foregroundColor: SafarColors.teal,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(latLng, zoom - 1);
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
            // Offline Map Download Action / Status Bar
            Positioned(
              top: 12,
              right: 12,
              child: _isDownloading
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              value: _downloadProgress > 0 ? _downloadProgress : null,
                              strokeWidth: 2,
                              color: SafarColors.teal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saving (${(_downloadProgress * 100).toInt()}%)',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : isDownloaded
                      ? InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Offline Map Saved'),
                                content: Text('Offline map for ${place.name} is stored locally (~1.2 MB). Remove offline cache?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Keep'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(offlineRegionsProvider.notifier).deleteRegion(regionId);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Offline map removed')),
                                      );
                                    },
                                    child: const Text('Remove', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: SafarColors.teal.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.offline_pin_rounded, color: Colors.white, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'Offline Ready',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _handleDownloadRegion(
                            latLng,
                            regionId,
                            place.districtName ?? place.name,
                          ),
                          icon: const Icon(Icons.download_for_offline_outlined, size: 15, color: SafarColors.saffron),
                          label: const Text(
                            'Save Offline Map',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
            ),
            if (place.sensitive)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.amber, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Approximate area shown (Rule 8)',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

