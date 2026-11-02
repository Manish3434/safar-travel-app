import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SavedPlace } from './entities/saved-place.entity';

@Injectable()
export class SavedPlacesService {
  // In-memory fallback if database connection is unavailable
  private readonly fallbackStore: Map<string, Set<string>> = new Map();

  constructor(
    @InjectRepository(SavedPlace)
    private readonly savedRepo: Repository<SavedPlace>,
  ) {}

  async getAll(userId: string): Promise<string[]> {
    try {
      const records = await this.savedRepo.find({
        where: { userId },
        order: { createdAt: 'DESC' },
      });
      return records.map((r) => r.placeId);
    } catch {
      return Array.from(this.fallbackStore.get(userId) ?? []);
    }
  }

  async save(userId: string, placeId: string): Promise<{ saved: boolean; place_id: string }> {
    try {
      const existing = await this.savedRepo.findOne({
        where: { userId, placeId },
      });
      if (!existing) {
        const entity = this.savedRepo.create({ userId, placeId });
        await this.savedRepo.save(entity);
      }
    } catch {
      if (!this.fallbackStore.has(userId)) {
        this.fallbackStore.set(userId, new Set());
      }
      this.fallbackStore.get(userId)!.add(placeId);
    }
    return { saved: true, place_id: placeId };
  }

  async remove(userId: string, placeId: string): Promise<{ removed: boolean; place_id: string }> {
    try {
      await this.savedRepo.delete({ userId, placeId });
    } catch {
      this.fallbackStore.get(userId)?.delete(placeId);
    }
    return { removed: true, place_id: placeId };
  }
}
