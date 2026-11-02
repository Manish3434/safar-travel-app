import { Controller, Get, Post, Delete, Param, Body, Req, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SavedPlacesService } from './saved-places.service';

@Controller('saved-places')
@UseGuards(AuthGuard('jwt'))
export class SavedPlacesController {
  constructor(private readonly savedPlaces: SavedPlacesService) {}

  /** GET /saved-places — list all saved places for the authenticated user */
  @Get()
  getAll(@Req() req: any) {
    return this.savedPlaces.getAll(req.user.userId);
  }

  /** POST /saved-places — save a place */
  @Post()
  save(@Req() req: any, @Body() body: { place_id: string }) {
    return this.savedPlaces.save(req.user.userId, body.place_id);
  }

  /** DELETE /saved-places/:placeId — remove a saved place */
  @Delete(':placeId')
  remove(@Req() req: any, @Param('placeId') placeId: string) {
    return this.savedPlaces.remove(req.user.userId, placeId);
  }
}
