import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/error/failures.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/rope_scrollbar.dart';
import '../../core/widgets/shimmer_skeleton.dart';
import 'models/place_models.dart';
import 'providers/search_provider.dart';
import 'repositories/places_repository.dart';
import 'providers/state_district_provider.dart';
import 'widgets/state_district_explorer.dart';
import 'widgets/cobra_voice_button.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;
  String _activeCategory = '';
  bool _isVoiceListening = false;

  void _toggleVoiceSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isVoiceListening = !_isVoiceListening;
    });
    if (_isVoiceListening) {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _isVoiceListening) {
          setState(() {
            _isVoiceListening = false;
            _controller.text = 'Ooty';
            _onSearchChanged('Ooty');
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        ref.read(searchQueryProvider.notifier).state = widget.initialQuery!;
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query.trim();
    });
  }

  void _selectCategory(String category) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activeCategory == category) {
        _activeCategory = '';
        _controller.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      } else {
        _activeCategory = category;
        _controller.text = category;
        ref.read(searchQueryProvider.notifier).state = category;
      }
    });
  }

  void _showSuggestPlaceSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _controller.text);
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
                      'Suggest a Place / Village',
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
                  'Know a remote waterfall, temple, or village? Help fellow travellers discover it.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Place or Village Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description & How to reach',
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
                      'submitted_at': DateTime.now().toIso8601String(),
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you! Your suggestion has been queued for review.')),
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
    final query = ref.watch(searchQueryProvider);
    final selectedState = ref.watch(selectedStateFilterProvider);
    final selectedDistrict = ref.watch(selectedDistrictFilterProvider);
    final hasActiveFilter = query.isNotEmpty || selectedState != null || selectedDistrict != null;
    final searchAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: widget.initialQuery == null || widget.initialQuery!.isEmpty,
          decoration: InputDecoration(
            hintText: l10n?.searchHint ?? 'Search cities, waterfalls, villages...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _activeCategory = '');
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CobraVoiceButton(
              size: 32,
              state: _isVoiceListening ? CobraVoiceState.listening : CobraVoiceState.idle,
              caption: _isVoiceListening ? 'Listening...' : null,
              onTap: _toggleVoiceSearch,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryFilter(
                  label: l10n?.all ?? 'All',
                  isSelected: _activeCategory.isEmpty,
                  onTap: () => _selectCategory(''),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🏖️ ${l10n?.beaches ?? "Beaches"}',
                  isSelected: _activeCategory == 'beach',
                  onTap: () => _selectCategory('beach'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🌿 ${l10n?.forest ?? "Forests"}',
                  isSelected: _activeCategory == 'forest',
                  onTap: () => _selectCategory('forest'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🦜 ${l10n?.birdSanctuary ?? "Bird Sanctuaries"}',
                  isSelected: _activeCategory == 'bird-sanctuary',
                  onTap: () => _selectCategory('bird-sanctuary'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🦁 ${l10n?.wildlife ?? "Wildlife"}',
                  isSelected: _activeCategory == 'wildlife',
                  onTap: () => _selectCategory('wildlife'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🏛️ ${l10n?.heritage ?? "Heritage"}',
                  isSelected: _activeCategory == 'heritage',
                  onTap: () => _selectCategory('heritage'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🖼️ ${l10n?.museum ?? "Museums"}',
                  isSelected: _activeCategory == 'museum',
                  onTap: () => _selectCategory('museum'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '💧 ${l10n?.waterfall ?? "Waterfalls"}',
                  isSelected: _activeCategory == 'waterfall',
                  onTap: () => _selectCategory('waterfall'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🏔️ ${l10n?.hillStation ?? "Hill Stations"}',
                  isSelected: _activeCategory == 'hill-station',
                  onTap: () => _selectCategory('hill-station'),
                  isDark: isDark,
                ),
                _buildCategoryFilter(
                  label: '🏙️ ${l10n?.city ?? "Cities"}',
                  isSelected: _activeCategory == 'city',
                  onTap: () => _selectCategory('city'),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (selectedState != null || selectedDistrict != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? SafarColors.darkCard : SafarColors.saffron.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : SafarColors.saffron.withOpacity(0.25),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: SafarColors.saffron),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📍 ${selectedState?.name ?? ""}${selectedDistrict != null ? " › ${selectedDistrict.name}" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(selectedDistrictFilterProvider.notifier).state = null;
                      ref.read(selectedStateFilterProvider.notifier).state = null;
                    },
                    icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                    label: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: !hasActiveFilter
                ? _buildInitialState(l10n, isDark)
                : searchAsync.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (_, __) => PlaceCardSkeleton(isDark: isDark),
                    ),
                    error: (err, stack) => _buildErrorState(err.toString(), query, theme, l10n),
                    data: (result) => result.when(
                      failure: (failure) => _buildFailureState(failure, query, theme, l10n),
                      success: (places) {
                        if (places.isEmpty) {
                          return _buildEmptyState(query, isDark, theme, l10n);
                        }

                        return RopeScrollbar(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await HapticFeedback.mediumImpact();
                              ref.invalidate(searchResultsProvider(query));
                              await ref.read(searchResultsProvider(query).future);
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                              itemCount: places.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final place = places[index];
                                return _SearchResultTile(
                                  place: place,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    context.go(AppRoutes.placeDetailPath(place.id));
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: SafarColors.saffron.withOpacity(0.2),
        checkmarkColor: SafarColors.saffron,
        labelStyle: TextStyle(
          color: isSelected
              ? SafarColors.saffronDark
              : (isDark ? SafarColors.textLight : SafarColors.textPrimary),
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildInitialState(AppLocalizations? l10n, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          StateExplorerCarousel(
            onStateSelected: (state) {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => DistrictSelectorSheet(
                  state: state,
                  onDistrictSelected: (dist) {
                    ref.read(selectedStateFilterProvider.notifier).state = state;
                    ref.read(selectedDistrictFilterProvider.notifier).state = dist;
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_outlined,
                    size: 56, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  l10n?.searchHint ?? 'Search cities, waterfalls, villages...',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String query, bool isDark, ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No places found for "$query"',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Searching a remote village or hidden trail? You can suggest it for verification.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SafarColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showSuggestPlaceSheet(context),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Suggest This Place'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureState(AppFailure failure, String query, ThemeData theme, AppLocalizations? l10n) {
    return Center(
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
            Text(
              failure.message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(searchResultsProvider(query)),
              child: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, String query, ThemeData theme, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(l10n?.errorLoading ?? 'Something went wrong', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => ref.refresh(searchResultsProvider(query)),
            child: Text(l10n?.retry ?? 'Retry'),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final PlaceResult place;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.place,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final displayName = locale == 'ta' && place.nameTa != null
        ? place.nameTa!
        : (locale == 'hi' && place.nameHi != null ? place.nameHi! : place.name);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? SafarColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
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
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: place.mainPhotoUrl != null
                    ? Image.network(
                        place.mainPhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark ? SafarColors.darkSurface : Colors.grey.shade200,
                          child: const Icon(Icons.landscape_rounded, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: isDark ? SafarColors.darkSurface : Colors.grey.shade200,
                        child: const Icon(Icons.landscape_rounded, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? SafarColors.textLight : SafarColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (place.rating != null) ...[
                        const Icon(Icons.star_rounded, size: 16, color: SafarColors.saffron),
                        const SizedBox(width: 2),
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (place.districtName != null || place.stateName != null)
                        Text(
                          '📍 ${place.districtName ?? place.stateName}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (place.sensitive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🛡️ PROTECTED',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
