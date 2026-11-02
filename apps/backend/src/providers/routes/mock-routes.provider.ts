import { Injectable } from '@nestjs/common';
import { RoutesProvider, RouteResult } from './routes.provider';

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

@Injectable()
export class MockRoutesProvider implements RoutesProvider {
  async getDistance(
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
  ): Promise<RouteResult> {
    // Straight-line distance with a 1.35× road-factor approximation
    const straightLine = haversineKm(originLat, originLng, destLat, destLng);
    const roadDistance = Math.round(straightLine * 1.35 * 10) / 10;
    // Assume average speed of 45 km/h on Indian roads
    const durationMinutes = Math.round((roadDistance / 45) * 60);

    return {
      origin_id: `${originLat},${originLng}`,
      destination_id: `${destLat},${destLng}`,
      distance_km: roadDistance,
      duration_minutes: durationMinutes,
      type: 'approximate', // labelled as approximate since it is not a real route
      source: 'mock',
      fetched_at: new Date().toISOString(),
    };
  }
}
