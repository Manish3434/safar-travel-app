// Models for the places API responses

class IndianState {
  final String code;
  final String name;
  final String? nameTa;
  final String? nameHi;
  final String imageUrl;
  final int districtCount;
  final int spotCount;
  final String type; // 'state' | 'union_territory'

  const IndianState({
    required this.code,
    required this.name,
    this.nameTa,
    this.nameHi,
    required this.imageUrl,
    required this.districtCount,
    required this.spotCount,
    this.type = 'state',
  });

  bool get isUnionTerritory => type == 'union_territory';

  factory IndianState.fromJson(Map<String, dynamic> json) {
    final nameLocal = json['nameLocal'] as Map<String, dynamic>?;
    return IndianState(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameTa: json['name_ta'] as String? ?? nameLocal?['ta'] as String?,
      nameHi: json['name_hi'] as String? ?? nameLocal?['hi'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String? ?? '',
      districtCount: json['district_count'] as int? ?? json['districtCount'] as int? ?? 0,
      spotCount: json['spot_count'] as int? ?? json['spotCount'] as int? ?? 0,
      type: json['type'] as String? ?? 'state',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'name_ta': nameTa,
        'name_hi': nameHi,
        'image_url': imageUrl,
        'district_count': districtCount,
        'spot_count': spotCount,
        'type': type,
      };
}

class District {
  final String id;
  final String stateCode;
  final String name;
  final String? nameTa;
  final String? nameHi;
  final String? headquarters;
  final int spotCount;
  final List<String> aliases;

  const District({
    required this.id,
    required this.stateCode,
    required this.name,
    this.nameTa,
    this.nameHi,
    this.headquarters,
    required this.spotCount,
    this.aliases = const [],
  });

  factory District.fromJson(Map<String, dynamic> json) {
    final nameLocal = json['nameLocal'] as Map<String, dynamic>?;
    final rawAliases = json['aliases'] as List?;
    return District(
      id: json['id'] as String? ?? json['lgd_code'] as String? ?? '',
      stateCode: json['state_code'] as String? ?? json['stateCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameTa: json['name_ta'] as String? ?? nameLocal?['ta'] as String?,
      nameHi: json['name_hi'] as String? ?? nameLocal?['hi'] as String?,
      headquarters: json['headquarters'] as String?,
      spotCount: json['spot_count'] as int? ?? json['spotCount'] as int? ?? 0,
      aliases: rawAliases?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'state_code': stateCode,
        'name': name,
        'name_ta': nameTa,
        'name_hi': nameHi,
        'headquarters': headquarters,
        'spot_count': spotCount,
        'aliases': aliases,
      };
}

class PlaceResult {
  final String id;
  final String name;
  final String? nameTa;
  final String? nameHi;
  final String category;
  final String? stateCode;
  final String? stateName;
  final String? districtId;
  final String? districtName;
  final String? mainPhotoUrl;
  final double? distanceKm;
  final double? rating;
  final String description;
  final LatLng location;
  final bool sensitive;
  final String source;
  final String fetchedAt;

  const PlaceResult({
    required this.id,
    required this.name,
    this.nameTa,
    this.nameHi,
    required this.category,
    this.stateCode,
    this.stateName,
    this.districtId,
    this.districtName,
    this.mainPhotoUrl,
    this.distanceKm,
    this.rating,
    required this.description,
    required this.location,
    required this.sensitive,
    required this.source,
    required this.fetchedAt,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) => PlaceResult(
        id: json['id'] as String,
        name: json['name'] as String,
        nameTa: json['name_ta'] as String?,
        nameHi: json['name_hi'] as String?,
        category: json['category'] as String,
        stateCode: json['state_code'] as String?,
        stateName: json['state_name'] as String?,
        districtId: json['district_id'] as String?,
        districtName: json['district_name'] as String?,
        mainPhotoUrl: json['main_photo_url'] as String?,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        rating: (json['rating'] as num?)?.toDouble(),
        description: json['description'] as String,
        location: LatLng.fromJson(json['location'] as Map<String, dynamic>),
        sensitive: json['sensitive'] as bool? ?? false,
        source: json['source'] as String,
        fetchedAt: json['fetched_at'] as String,
      );
}

class PlaceDetail extends PlaceResult {
  final List<String> photos;
  final String? openingHours;
  final String? howToReach;
  final bool permitRequired;
  final bool guideRequired;
  final String? difficulty;
  final String? bestSeason;
  final String? networkInfo;
  final List<String> warnings;
  final String? nearestHospital;

  const PlaceDetail({
    required super.id,
    required super.name,
    super.nameTa,
    super.nameHi,
    required super.category,
    super.stateCode,
    super.stateName,
    super.districtId,
    super.districtName,
    super.mainPhotoUrl,
    super.distanceKm,
    super.rating,
    required super.description,
    required super.location,
    required super.sensitive,
    required super.source,
    required super.fetchedAt,
    required this.photos,
    this.openingHours,
    this.howToReach,
    required this.permitRequired,
    required this.guideRequired,
    this.difficulty,
    this.bestSeason,
    this.networkInfo,
    this.warnings = const [],
    this.nearestHospital,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) => PlaceDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        nameTa: json['name_ta'] as String?,
        nameHi: json['name_hi'] as String?,
        category: json['category'] as String,
        stateCode: json['state_code'] as String?,
        stateName: json['state_name'] as String?,
        districtId: json['district_id'] as String?,
        districtName: json['district_name'] as String?,
        mainPhotoUrl: json['main_photo_url'] as String?,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        rating: (json['rating'] as num?)?.toDouble(),
        description: json['description'] as String,
        location: LatLng.fromJson(json['location'] as Map<String, dynamic>),
        sensitive: json['sensitive'] as bool? ?? false,
        source: json['source'] as String,
        fetchedAt: json['fetched_at'] as String,
        photos: List<String>.from(json['photos'] as List? ?? []),
        openingHours: json['opening_hours'] as String?,
        howToReach: json['how_to_reach'] as String?,
        permitRequired: json['permit_required'] as bool? ?? false,
        guideRequired: json['guide_required'] as bool? ?? false,
        difficulty: json['difficulty'] as String?,
        bestSeason: json['best_season'] as String?,
        networkInfo: json['network_info'] as String?,
        warnings: List<String>.from(json['warnings'] as List? ?? []),
        nearestHospital: json['nearest_hospital'] as String?,
      );
}

class LatLng {
  final double lat;
  final double lng;

  const LatLng({required this.lat, required this.lng});

  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}
