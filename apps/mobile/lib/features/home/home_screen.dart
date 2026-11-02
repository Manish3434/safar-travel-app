import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/widgets/rope_scrollbar.dart';
import '../search/widgets/state_district_explorer.dart';
import '../search/providers/state_district_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
      body: RopeScrollbar(
        controller: _scrollController,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n?.appTitle ?? "Safar"} 🗺️',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n?.whereDoYouWantToGo ?? 'Where do you want to go?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF0F2B2E), const Color(0xFF0D1117)]
                        : [SafarColors.saffron.withOpacity(0.18), Colors.grey.shade50],
                  ),
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.savedPlaces);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF21262D) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          // ── Search Bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Hero(
                tag: 'search-bar',
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.search);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161B22) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n?.searchHint ?? 'Search cities, waterfalls, villages...',
                              style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.my_location_rounded,
                            color: isDark ? Colors.grey.shade400 : SafarColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── State Explorer (India's 28 States & UTs) ──────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 16.0),
              child: StateExplorerCarousel(
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
                        context.push(
                          AppRoutes.districtPlaces,
                          extra: {
                            'district': dist,
                            'state': state,
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Category Tiles (Vibrant Blue Square Tiles) ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _CategoryTile(icon: '🏖️', label: l10n?.beaches ?? 'Beaches', category: 'beach'),
                    _CategoryTile(icon: '🌿', label: l10n?.forest ?? 'Forests', category: 'forest'),
                    _CategoryTile(icon: '🦜', label: l10n?.birdSanctuary ?? 'Bird Sanctuaries', category: 'bird-sanctuary'),
                    _CategoryTile(icon: '🦁', label: l10n?.wildlife ?? 'Wildlife', category: 'wildlife'),
                    _CategoryTile(icon: '🏛️', label: l10n?.heritage ?? 'Heritage', category: 'heritage'),
                    _CategoryTile(icon: '🖼️', label: l10n?.museum ?? 'Museums', category: 'museum'),
                    _CategoryTile(icon: '💧', label: l10n?.waterfall ?? 'Waterfalls', category: 'waterfall'),
                    _CategoryTile(icon: '🏔️', label: l10n?.hillStation ?? 'Hill Stations', category: 'hill-station'),
                  ],
                ),
              ),
            ),
          ),

          // ── Section: Popular Destinations ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.popularDestinations ?? 'Popular Destinations',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Featured Spots',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 295,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _popularDestinations(context, isDark),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentNavIndex = index);
            if (index == 1) {
              context.push(AppRoutes.offlineMaps);
            } else if (index == 3) {
              context.go(AppRoutes.savedPlaces);
            }
          },
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          selectedItemColor: const Color(0xFF38BDF8),
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _popularDestinations(BuildContext context, bool isDark) {
    final destinations = [
      (
        'tn-002',
        'Ooty',
        'Ooty is a serene hill station nestled in Nilgiri hills with tea gardens.',
        'Tamil Nadu',
        '14.9 km',
        '4.8',
        'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?auto=format&fit=crop&w=800&q=80',
      ),
      (
        'kl-002',
        'Bekal',
        'Bekal trails along the sea coast with historical keyhole fort.',
        'Kerala',
        '14.2 km',
        '4.8',
        'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944?auto=format&fit=crop&w=800&q=80',
      ),
      (
        'ka-003',
        'Hampi',
        'Hampi institutes with historic stone chariot and Virupaksha ruins.',
        'Karnataka',
        '18.5 km',
        '4.9',
        'https://images.unsplash.com/photo-1600100397608-f010f4438317?auto=format&fit=crop&w=800&q=80',
      ),
      (
        'mh-001',
        'Ajanta',
        'Ancient rock-cut Buddhist cave monuments dating from 2nd century BCE.',
        'Maharashtra',
        '22.0 km',
        '4.7',
        'https://images.unsplash.com/photo-1570168007204-dfb528c6958f?auto=format&fit=crop&w=800&q=80',
      ),
    ];

    return destinations
        .map((d) => _DestinationCard(
              placeId: d.$1,
              name: d.$2,
              snippet: d.$3,
              stateName: d.$4,
              distance: d.$5,
              rating: d.$6,
              imageUrl: d.$7,
              isDark: isDark,
            ))
        .toList();
  }
}

class _CategoryTile extends StatelessWidget {
  final String icon;
  final String label;
  final String category;

  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go('${AppRoutes.search}?q=$category');
      },
      child: Container(
        width: 92,
        height: 84,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0EA5E9),
              Color(0xFF0284C7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final String placeId;
  final String name;
  final String snippet;
  final String stateName;
  final String distance;
  final String rating;
  final String imageUrl;
  final bool isDark;

  const _DestinationCard({
    required this.placeId,
    required this.name,
    required this.snippet,
    required this.stateName,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 205,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with badges
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark ? const Color(0xFF21262D) : Colors.grey.shade200,
                      child: const Icon(Icons.terrain, color: Colors.grey),
                    ),
                  ),
                ),
                // Distance badge top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      distance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Rating badge bottom-left
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    snippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 2),
                      Text(
                        stateName,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.placeDetailPath(placeId));
                    },
                    child: Container(
                      height: 34,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF21262D) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
}
