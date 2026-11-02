import { Injectable, Inject } from '@nestjs/common';
import { TRANSPORT_PROVIDER, TransportProvider } from '../providers/transport/transport.provider';
import { CalculateDistanceDto } from './transport.controller';

@Injectable()
export class TransportService {
  constructor(
    @Inject(TRANSPORT_PROVIDER) private readonly transport: TransportProvider,
  ) {}

  getRoutes(from: string, to: string, date?: string) {
    return this.transport.getRoutes(from, to, date);
  }

  calculateDistanceAndRoutes(dto: CalculateDistanceDto) {
    const lat1 = Number(dto.originLat) || 11.0168;
    const lon1 = Number(dto.originLng) || 76.9558;
    const lat2 = Number(dto.destLat) || 9.6050;
    const lon2 = Number(dto.destLng) || 77.0100;

    const R = 6371; // Earth's radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const aerialKm = R * c;

    // Realistic road distance with 1.25 winding index
    const roadKm = Math.round(Math.max(1, aerialKm * 1.25) * 10) / 10;

    const formatMins = (mins: number) => {
      if (mins < 60) return `${mins}m`;
      const h = Math.floor(mins / 60);
      const m = mins % 60;
      return m > 0 ? `${h}h ${m}m` : `${h}h`;
    };

    const carMins = Math.max(3, Math.round((roadKm / 58) * 60));
    const bikeMins = Math.max(4, Math.round((roadKm / 40) * 60));
    const trainMins = Math.max(20, Math.round((roadKm / 48) * 60 + 30));
    const walkMins = Math.max(5, Math.round((roadKm / 4.5) * 60));

    let flightStr = 'Not recommended (drive faster)';
    let flightAvailable = false;
    if (roadKm >= 200) {
      const flightMins = Math.round((roadKm / 550) * 60 + 85);
      flightStr = formatMins(flightMins);
      flightAvailable = true;
    }

    return {
      success: true,
      origin: dto.origin || 'Detected Location',
      destination: dto.destination || 'Destination Spot',
      distanceKm: roadKm,
      aerialDistanceKm: Math.round(aerialKm * 10) / 10,
      modes: {
        car: {
          label: 'Drive / Car',
          icon: '🚗',
          duration: formatMins(carMins),
          distanceKm: roadKm,
          estimatedFuelInr: Math.round(roadKm * 9.5),
          routeNote: 'Fastest highway route • Scenic mountain approach'
        },
        bike: {
          label: 'Bike / Motorcycle',
          icon: '🏍️',
          duration: formatMins(bikeMins),
          distanceKm: roadKm,
          estimatedFuelInr: Math.round(roadKm * 2.3),
          routeNote: 'Scenic curves and valley view state highway'
        },
        train: {
          label: 'Train / Intercity Bus',
          icon: '🚆',
          duration: formatMins(trainMins),
          distanceKm: roadKm,
          routeNote: 'Express rail or regional bus connection'
        },
        flight: {
          label: 'Flight',
          icon: '✈️',
          duration: flightStr,
          distanceKm: roadKm,
          available: flightAvailable,
          routeNote: flightAvailable
            ? 'Regional airport transit included (approx. 85m buffer)'
            : 'Road or rail travel is faster for distances under 200 km'
        },
        walk: {
          label: 'Walk / Trek',
          icon: '🚶',
          duration: formatMins(walkMins),
          distanceKm: roadKm,
          caloriesKcal: Math.round(roadKm * 65),
          routeNote: 'Cross-country trail • Elevation changes apply'
        }
      },
      googleMapsUrl: `https://www.google.com/maps/dir/?api=1&origin=${lat1},${lon1}&destination=${lat2},${lon2}&travelmode=driving`
    };
  }
}
