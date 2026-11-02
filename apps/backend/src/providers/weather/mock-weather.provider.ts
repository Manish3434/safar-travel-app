import { Injectable } from '@nestjs/common';
import {
  WeatherProvider,
  WeatherCurrent,
  WeatherForecast,
} from './weather.provider';

/** Returns realistic seasonal weather for South India / Maharashtra */
@Injectable()
export class MockWeatherProvider implements WeatherProvider {
  private getSeason(): 'winter' | 'summer' | 'monsoon' | 'post-monsoon' {
    const month = new Date().getMonth() + 1; // 1–12
    if (month >= 12 || month <= 2) return 'winter';
    if (month >= 3 && month <= 5) return 'summer';
    if (month >= 6 && month <= 9) return 'monsoon';
    return 'post-monsoon';
  }

  private baseConditions(): { temp: number; condition: string; rain: number } {
    const s = this.getSeason();
    switch (s) {
      case 'winter':      return { temp: 22, condition: 'Sunny', rain: 5 };
      case 'summer':      return { temp: 36, condition: 'Hot and Hazy', rain: 10 };
      case 'monsoon':     return { temp: 27, condition: 'Heavy Rain', rain: 85 };
      case 'post-monsoon': return { temp: 28, condition: 'Partly Cloudy', rain: 30 };
    }
  }

  async getCurrent(placeId: string, lat: number, lng: number): Promise<WeatherCurrent> {
    const { temp, condition } = this.baseConditions();
    return {
      place_id: placeId,
      temperature_c: temp,
      feels_like_c: temp - 2,
      humidity_pct: 70,
      condition,
      condition_icon: 'https://openweathermap.org/img/wn/02d@2x.png',
      wind_kmh: 14,
      is_approximate: false,
      source: 'mock',
      fetched_at: new Date().toISOString(),
    };
  }

  async getForecast(placeId: string, lat: number, lng: number): Promise<WeatherForecast> {
    const current = await this.getCurrent(placeId, lat, lng);
    const { temp, condition, rain } = this.baseConditions();

    const daily = Array.from({ length: 10 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() + i);
      return {
        date: d.toISOString().split('T')[0],
        max_c: temp + Math.round(Math.random() * 3),
        min_c: temp - 5 + Math.round(Math.random() * 2),
        condition,
        condition_icon: 'https://openweathermap.org/img/wn/02d@2x.png',
        rain_chance_pct: rain,
      };
    });

    const hourly = Array.from({ length: 24 }, (_, h) => ({
      time: `${String(h).padStart(2, '0')}:00`,
      temp_c: temp - 3 + Math.round(Math.sin((h / 24) * Math.PI) * 5),
      condition,
    }));

    return {
      place_id: placeId,
      current,
      hourly,
      daily,
      is_approximate: false,
      source: 'mock',
      fetched_at: new Date().toISOString(),
    };
  }
}
