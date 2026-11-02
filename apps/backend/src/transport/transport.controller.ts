import { Controller, Get, Query } from '@nestjs/common';
import { TransportService } from './transport.service';
import { IsString, IsOptional } from 'class-validator';

class RoutesDto {
  @IsString() from: string;
  @IsString() to: string;
  @IsOptional() @IsString() date?: string;
}

export class CalculateDistanceDto {
  @IsOptional() @IsString() origin?: string;
  @IsOptional() @IsString() destination?: string;
  @IsOptional() originLat?: string | number;
  @IsOptional() originLng?: string | number;
  @IsOptional() destLat?: string | number;
  @IsOptional() destLng?: string | number;
}

@Controller('transport')
export class TransportController {
  constructor(private readonly transportService: TransportService) {}

  /** GET /transport/routes?from=Chennai&to=Hogenakkal&date=2026-11-15 */
  @Get('routes')
  getRoutes(@Query() dto: RoutesDto) {
    return this.transportService.getRoutes(dto.from, dto.to, dto.date);
  }

  /** GET /transport/calculate?origin=Coimbatore&destination=Parunthumpara&originLat=11.0168&originLng=76.9558&destLat=9.605&destLng=77.01 */
  @Get('calculate')
  calculateDistance(@Query() dto: CalculateDistanceDto) {
    return this.transportService.calculateDistanceAndRoutes(dto);
  }
}
