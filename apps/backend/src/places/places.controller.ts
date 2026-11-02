import { Controller, Get, Param, Query } from '@nestjs/common';
import { PlacesService } from './places.service';
import { SearchPlacesDto, NearbyPlacesDto, DistanceDto } from './dto/places.dto';

@Controller('places')
export class PlacesController {
  constructor(private readonly placesService: PlacesService) {}

  /** GET /places/states — returns all 28 states & UTs */
  @Get('states')
  getStates() {
    return this.placesService.getStates();
  }

  /** GET /places/states/:stateCode/districts — returns all districts (e.g. 38 for TN) */
  @Get('states/:stateCode/districts')
  getDistricts(@Param('stateCode') stateCode: string) {
    return this.placesService.getDistricts(stateCode);
  }

  /** GET /places/districts/:districtId?category=beach — returns tourist spots in that district */
  @Get('districts/:districtId')
  getPlacesByDistrict(
    @Param('districtId') districtId: string,
    @Query('category') category?: string,
  ) {
    return this.placesService.getPlacesByDistrict(districtId, category);
  }

  /** GET /places/search?q=waterfall&state=TN&district=tn-nilgiris&category=wildlife */
  @Get('search')
  search(@Query() dto: SearchPlacesDto) {
    return this.placesService.search(
      dto.q ?? '',
      dto.lat,
      dto.lng,
      dto.state,
      dto.district,
      dto.category,
    );
  }

  /** GET /places/nearby?lat=13.08&lng=80.27&radius=100&category=waterfall */
  @Get('nearby')
  nearby(@Query() dto: NearbyPlacesDto) {
    return this.placesService.getNearby(dto.lat, dto.lng, dto.radius ?? 50, dto.category);
  }

  /** GET /places/:id */
  @Get(':id')
  getById(@Param('id') id: string) {
    return this.placesService.getById(id);
  }

  /** GET /places/:id/distance?lat=13.08&lng=80.27 */
  @Get(':id/distance')
  getDistance(@Param('id') id: string, @Query() dto: DistanceDto) {
    return this.placesService.getDistance(id, dto.lat, dto.lng);
  }
}
