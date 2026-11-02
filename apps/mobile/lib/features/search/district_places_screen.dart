import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/error/failures.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import 'models/place_models.dart';
import 'providers/search_provider.dart';
import 'repositories/places_repository.dart';

class DistrictPlacesScreen extends ConsumerStatefulWidget {
  final District district;
  final IndianState state;

  const DistrictPlacesScreen({
    super.key,
    required this.district,
    required this.state,
  });

  @override
  ConsumerState<DistrictPlacesScreen> createState() => _DistrictPlacesScreenState();
}

class _DistrictPlacesScreenState extends ConsumerState<DistrictPlacesScreen> {
  String _selectedCategory = 'all';

  void _onCategorySelected(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
  }

  void _showSuggestSpotSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? SafarColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Suggest Spot in ${widget.district.name}',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Know a beach, forest trail, bird sanctuary or heritage temple in ${widget.district.name}? Suggest it here.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Attraction / Spot Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description, Category & How to reach',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafarColors.saffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await ref.read(placesRepositoryProvider).suggestPlace(suggestionData: {
                      'name': nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'district': widget.district.id,
                      'state': widget.state.code,
                      'submitted_at': DateTime.now().toIso8601String(),
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you! Your spot suggestion has been submitted for review.')),
                      );
                    }
                  },
                  child: const Text('Submit Suggestion', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final spotsAsync = ref.watch(districtPlacesProvider((
      districtId: widget.district.id,
      category: _selectedCategory == 'all' ? null : _selectedCategory,
    )));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.district.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.state.name} ${widget.district.nameTa != null ? "• ${widget.district.nameTa}" : ""}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Suggest spot',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSuggestSpotSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category Filter Bar Pinned Above Trip Spots ─────────────────
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? SafarColors.darkSurface : Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                ),
              ),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryPill(
                  id: 'all',
                  label: l10n?.all ?? 'All',
                  icon: '✨',
                  isSelected: _selectedCategory == 'all',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'beach',
                  label: l10n?.beaches ?? 'Beaches',
                  icon: '🏖️',
                  isSelected: _selectedCategory == 'beach',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'forest',
                  label: l10n?.forest ?? 'Forests',
                  icon: '🌿',
                  isSelected: _selectedCategory == 'forest',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'bird-sanctuary',
                  label: l10n?.birdSanctuary ?? 'Bird Sanctuaries',
                  icon: '🦜',
                  isSelected: _selectedCategory == 'bird-sanctuary',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'wildlife',
                  label: l10n?.wildlife ?? 'Wildlife',
                  icon: '🦁',
                  isSelected: _selectedCategory == 'wildlife',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'heritage',
                  label: l10n?.heritage ?? 'Heritage',
                  icon: '🏛️',
                  isSelected: _selectedCategory == 'heritage',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'museum',
                  label: l10n?.museum ?? 'Museums',
                  icon: '🖼️',
                  isSelected: _selectedCategory == 'museum',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'waterfall',
                  label: l10n?.waterfall ?? 'Waterfalls',
                  icon: '💧',
                  isSelected: _selectedCategory == 'waterfall',
                  isDark: isDark,
                ),
                _buildCategoryPill(
                  id: 'hill-station',
                  label: l10n?.hillStation ?? 'Hill Stations',
                  icon: '🏔️',
                  isSelected: _selectedCategory == 'hill-station',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ── Trip Spots List ─────────────────────────────────────────────
          Expanded(
            child: spotsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => PlaceCardSkeleton(isDark: isDark),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(l10n?.errorLoading ?? 'Failed to load trip spots', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(districtPlacesProvider((
                          districtId: widget.district.id,
                          category: _selectedCategory == 'all' ? null : _selectedCategory,
                        ))),
                        child: Text(l10n?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (result) => result.when(
                failure: (failure) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          failure is NetworkFailure ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(failure.message, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(districtPlacesProvider((
                            districtId: widget.district.id,
                            category: _selectedCategory == 'all' ? null : _selectedCategory,
                          ))),
                          child: Text(l10n?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                success: (places) {
                  if (places.isEmpty) {
                    return _buildEmptyCategoryView(isDark, theme);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    itemCount: places.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final spot = places[index];
                      return _DistrictSpotCard(
                        place: spot,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(AppRoutes.placeDetailPath(spot.id));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill({
    required String id,
    required String label,
    required String icon,
    required bool isSelected,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _onCategorySelected(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F766E)
                : (isDark ? const Color(0xFF161B22) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF14B8A6)
                  : (isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon.isNotEmpty) ...[
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white.withOpacity(0.85) : SafarColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCategoryView(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: isDark ? SafarColors.darkCard : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.explore_off_rounded, size: 36, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $_selectedCategory spots found in ${widget.district.name}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Know a place here? You can suggest it to help travelers discover remote spots.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedCategory != 'all')
                  OutlinedButton(
                    onPressed: () => _onCategorySelected('all'),
                    child: const Text('View All Attractions'),
                  ),
                if (_selectedCategory != 'all') const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SafarColors.saffron,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showSuggestSpotSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Suggest Spot'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DistrictSpotCard extends StatelessWidget {
  final PlaceResult place;
  final bool isDark;
  final VoidCallback onTap;

  const _DistrictSpotCard({
    required this.place,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final displayName = locale == 'ta' && place.nameTa != null
        ? place.nameTa!
        : (locale == 'hi' && place.nameHi != null ? place.nameHi! : place.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Width Hero Image with Floating Badges
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: place.mainPhotoUrl != null && place.mainPhotoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.mainPhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark ? const Color(0xFF21262D) : Colors.grey.shade200,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark ? const Color(0xFF21262D) : Colors.grey.shade200,
                            child: const Icon(Icons.landscape_rounded, size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: isDark ? const Color(0xFF21262D) : Colors.grey.shade200,
                          child: const Icon(Icons.landscape_rounded, size: 40, color: Colors.grey),
                        ),
                ),
                // Gradient for contrast
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Bottom-left Category Badge
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_categoryEmoji(place.category), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          _categoryLabel(place.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-right Rating Badge
                if (place.rating != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Protected Flag
                if (place.sensitive)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PROTECTED',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.rating != null)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.description,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // Full-width button: View Map & Details
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      height: 42,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF21262D) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'View Map & Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return '🏖️';
      case 'forest':
        return '🌿';
      case 'bird-sanctuary':
        return '🦜';
      case 'wildlife':
        return '🦁';
      case 'heritage':
        return '🏛️';
      case 'museum':
        return '🖼️';
      case 'waterfall':
        return '💧';
      case 'hill-station':
        return '🏔️';
      default:
        return '📍';
    }
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return 'Beach';
      case 'forest':
        return 'Forest';
      case 'bird-sanctuary':
        return 'Bird Sanctuary';
      case 'wildlife':
        return 'Wildlife';
      case 'heritage':
        return 'Heritage';
      case 'museum':
        return 'Museum';
      case 'waterfall':
        return 'Waterfall';
      case 'hill-station':
        return 'Hill Station';
      default:
        return category.toUpperCase();
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'beach':
        return Colors.teal;
      case 'forest':
        return Colors.green;
      case 'bird-sanctuary':
        return Colors.deepOrange;
      case 'wildlife':
        return Colors.orange;
      case 'heritage':
        return Colors.purple;
      case 'museum':
        return Colors.indigo;
      case 'waterfall':
        return Colors.blue;
      case 'hill-station':
        return Colors.cyan;
      default:
        return SafarColors.saffron;
    }
  }
}
