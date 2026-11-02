import { Controller, Get, Param, Query } from '@nestjs/common';
import { RegionsService } from './regions.service';
import { SearchRegionsDto } from './dto/regions.dto';

@Controller('regions')
export class RegionsController {
  constructor(private readonly regionsService: RegionsService) {}

  /**
   * GET /api/v1/regions/states
   * Returns all 28 States and 8 Union Territories with localized names and district counts.
   * Query params: ?type=state|union_territory&search=tamil
   */
  @Get('states')
  getStates(@Query() dto: SearchRegionsDto) {
    return this.regionsService.getStates(dto);
  }

  /**
   * GET /api/v1/regions/states/:stateId/districts
   * Returns all canonical districts belonging to a given State or UT.
   * Query params: ?search=madurai
   */
  @Get('states/:stateId/districts')
  getStateDistricts(
    @Param('stateId') stateId: string,
    @Query('search') search?: string,
  ) {
    return this.regionsService.getDistricts(stateId, search);
  }

  /**
   * GET /api/v1/regions/:stateId/districts
   * Clean route alias for mobile/frontend convenience.
   */
  @Get(':stateId/districts')
  getDistricts(
    @Param('stateId') stateId: string,
    @Query('search') search?: string,
  ) {
    return this.regionsService.getDistricts(stateId, search);
  }
}
