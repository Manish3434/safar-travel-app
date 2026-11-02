// Models for Place Detail auxiliary data (weather, stays, transport, distance)

class WeatherData {
  final double temperatureC;
  final double feelsLikeC;
  final int humidityPct;
  final String condition;
  final String conditionIcon;
  final double windKmh;
  final bool isApproximate;
  final List<DayForecast> forecast;

  WeatherData({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidityPct,
    required this.condition,
    required this.conditionIcon,
    required this.windKmh,
    required this.isApproximate,
    required this.forecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final cur = json['current'] as Map<String, dynamic>? ?? json;
    final dailyList = (json['daily'] as List? ?? []);
    return WeatherData(
      temperatureC: (cur['temperature_c'] as num?)?.toDouble() ?? 25.0,
      feelsLikeC: (cur['feels_like_c'] as num?)?.toDouble() ?? 25.0,
      humidityPct: (cur['humidity_pct'] as num?)?.toInt() ?? 60,
      condition: cur['condition'] as String? ?? 'Clear',
      conditionIcon: cur['condition_icon'] as String? ?? '',
      windKmh: (cur['wind_kmh'] as num?)?.toDouble() ?? 10.0,
      isApproximate: cur['is_approximate'] as bool? ?? false,
      forecast: dailyList.map((d) => DayForecast.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }
}

class DayForecast {
  final String date;
  final double maxC;
  final double minC;
  final String condition;
  final int rainChancePct;

  DayForecast({
    required this.date,
    required this.maxC,
    required this.minC,
    required this.condition,
    required this.rainChancePct,
  });

  factory DayForecast.fromJson(Map<String, dynamic> json) {
    return DayForecast(
      date: json['date'] as String? ?? '',
      maxC: (json['max_c'] as num?)?.toDouble() ?? 30.0,
      minC: (json['min_c'] as num?)?.toDouble() ?? 20.0,
      condition: json['condition'] as String? ?? 'Sunny',
      rainChancePct: (json['rain_chance_pct'] as num?)?.toInt() ?? 0,
    );
  }
}

class StayItem {
  final String id;
  final String name;
  final String type;
  final int pricePerNightInr;
  final double rating;
  final double distanceKm;
  final String address;
  final List<String> amenities;

  StayItem({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerNightInr,
    required this.rating,
    required this.distanceKm,
    required this.address,
    required this.amenities,
  });

  factory StayItem.fromJson(Map<String, dynamic> json) {
    return StayItem(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      pricePerNightInr: (json['price_per_night_inr'] as num).toInt(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 1.0,
      address: json['address'] as String? ?? '',
      amenities: List<String>.from(json['amenities'] as List? ?? []),
    );
  }
}

class TransportTrip {
  final String operator;
  final String busType;
  final String departsAt;
  final String arrivesAt;
  final int fareInr;
  final String lastUpdated;

  TransportTrip({
    required this.operator,
    required this.busType,
    required this.departsAt,
    required this.arrivesAt,
    required this.fareInr,
    required this.lastUpdated,
  });

  factory TransportTrip.fromJson(Map<String, dynamic> json) {
    return TransportTrip(
      operator: json['operator'] as String? ?? 'State Transport',
      busType: json['bus_type'] as String? ?? 'Standard',
      departsAt: json['departs_at'] as String? ?? '',
      arrivesAt: json['arrives_at'] as String? ?? '',
      fareInr: (json['fare_inr'] as num?)?.toInt() ?? 0,
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }
}

class TransportResult {
  final bool available;
  final String? reason;
  final List<TransportTrip> trips;

  TransportResult({
    required this.available,
    this.reason,
    required this.trips,
  });

  factory TransportResult.fromJson(Map<String, dynamic> json) {
    final list = (json['trips'] as List? ?? []);
    return TransportResult(
      available: json['available'] as bool? ?? false,
      reason: json['reason'] as String?,
      trips: list.map((t) => TransportTrip.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}
