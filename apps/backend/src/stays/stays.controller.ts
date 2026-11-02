import { Controller, Get, Param, Query } from '@nestjs/common';
import { StaysService } from './stays.service';
import { IsOptional, IsNumber, IsString } from 'class-validator';
import { Type } from 'class-transformer';

class StaysFilterDto {
  @IsOptional() @Type(() => Number) @IsNumber() price_max?: number;
  @IsOptional() @Type(() => Number) @IsNumber() rating_min?: number;
  @IsOptional() @IsString() type?: any;
}

@Controller('places')
export class StaysController {
  constructor(private readonly staysService: StaysService) {}

  /** GET /places/:id/stays?price_max=3000&rating_min=4&type=homestay */
  @Get(':id/stays')
  getStays(@Param('id') id: string, @Query() filters: StaysFilterDto) {
    return this.staysService.getNearPlace(id, filters);
  }
}
