import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/default_places_data.dart';
import '../models/place_models.dart';
import '../providers/state_district_provider.dart';

/// Horizontal carousel displaying India's 28 States & 8 UTs
class StateExplorerCarousel extends ConsumerWidget {
  final void Function(IndianState state)? onStateSelected;

  const StateExplorerCarousel({super.key, this.onStateSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statesAsync = ref.watch(statesProvider);
    final selectedState = ref.watch(selectedStateFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Explore States & UTs (36 Regions)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to pick district',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: statesAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: SafarColors.saffron),
              ),
            ),
            error: (_, __) => _buildStatesList(context, ref, DEFAULT_STATES, selectedState),
            data: (result) {
              final states = result.when(
                success: (data) => data.isNotEmpty ? data : DEFAULT_STATES,
                failure: (_) => DEFAULT_STATES,
              );
              return _buildStatesList(context, ref, states, selectedState);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatesList(
    BuildContext context,
    WidgetRef ref,
    List<IndianState> states,
    IndianState? selectedState,
  ) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: states.length,
      itemBuilder: (context, index) {
        final state = states[index];
        final isSelected = selectedState?.code == state.code;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(selectedStateFilterProvider.notifier).state = state;
            if (onStateSelected != null) {
              onStateSelected!(state);
            } else {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => DistrictSelectorSheet(state: state),
              );
            }
          },
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? SafarColors.saffron : Colors.white.withOpacity(0.12),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: state.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.terrain, color: Colors.grey),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.88),
                        ],
                        stops: const [0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getStateHighlight(state),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${state.districtCount} Districts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStateHighlight(IndianState state) {
    switch (state.code) {
      case 'TN':
        return 'Meenakshi Amman Temple';
      case 'KL':
        return 'Backwaters & Kovalam';
      case 'KA':
        return 'Mysore Palace & Hampi';
      case 'HP':
        return 'Snow-capped Himalayas';
      case 'AP':
        return 'Tirupati & Araku Valley';
      case 'MH':
        return 'Ajanta & Western Ghats';
      case 'GA':
        return 'Beaches & Heritage';
      case 'RJ':
        return 'Royal Forts & Palaces';
      case 'UK':
        return 'Char Dham & Rishikesh';
      case 'WB':
        return 'Darjeeling & Sundarbans';
      case 'TG':
        return 'Charminar & Golconda';
      default:
        return state.nameTa ?? state.nameHi ?? 'Explore India';
    }
  }
}

/// Bottom sheet displaying all districts of a selected state (e.g. 38 for Tamil Nadu)
class DistrictSelectorSheet extends ConsumerStatefulWidget {
  final IndianState state;
  final ValueChanged<District>? onDistrictSelected;

  const DistrictSelectorSheet({
    super.key,
    required this.state,
    this.onDistrictSelected,
  });

  @override
  ConsumerState<DistrictSelectorSheet> createState() => _DistrictSelectorSheetState();
}

class _DistrictSelectorSheetState extends ConsumerState<DistrictSelectorSheet> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final districtsAsync = ref.watch(stateDistrictsProvider(widget.state.code));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? SafarColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.state.districtCount} Districts (${widget.state.nameTa ?? ""})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search district (e.g. Nilgiris, Madurai)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                filled: true,
                fillColor: isDark ? SafarColors.darkCard : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _filterQuery = val.toLowerCase().trim()),
            ),
          ),
          const SizedBox(height: 12),
          // Districts Grid / List
          Expanded(
            child: districtsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: SafarColors.saffron)),
              error: (_, __) => _buildDistrictsList(context, getFallbackDistrictsForState(widget.state.code), isDark),
              data: (result) {
                final districts = result.when(
                  success: (data) => data.isNotEmpty ? data : getFallbackDistrictsForState(widget.state.code),
                  failure: (_) => getFallbackDistrictsForState(widget.state.code),
                );
                return _buildDistrictsList(context, districts, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictsList(BuildContext context, List<District> districts, bool isDark) {
    final filtered = districts.filterDistricts(_filterQuery);

    if (filtered.isEmpty) {
      return const Center(child: Text('No districts match your search'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final dist = filtered[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Text(
            dist.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            dist.nameTa ?? dist.nameHi ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          trailing: dist.spotCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SafarColors.saffron.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '★ ${dist.spotCount} spots',
                    style: const TextStyle(
                      color: SafarColors.saffron,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
              : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedDistrictFilterProvider.notifier).state = dist;
            Navigator.of(context).pop();
            if (widget.onDistrictSelected != null) {
              widget.onDistrictSelected!(dist);
            } else {
              context.push(
                AppRoutes.districtPlaces,
                extra: {
                  'district': dist,
                  'state': widget.state,
                },
              );
            }
          },
        );
      },
    );
  }
}

/// Helper extension on list of districts
extension DistrictListFilter on List<District> {
  List<District> filterDistricts(String query) {
    if (query.isEmpty) return this;
    return where((d) {
      final nameMatches = d.name.toLowerCase().contains(query);
      final taMatches = d.nameTa?.toLowerCase().contains(query) ?? false;
      final hiMatches = d.nameHi?.toLowerCase().contains(query) ?? false;
      return nameMatches || taMatches || hiMatches;
    }).toList();
  }
}

class BoxInsets {
  static final darkCardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );
}
