import { IsOptional, IsString, IsIn } from 'class-validator';

export class SearchRegionsDto {
  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @IsIn(['state', 'union_territory'])
  type?: 'state' | 'union_territory';
}

export interface StateResponseDto {
  code: string;
  name: string;
  nameLocal?: Record<string, string>;
  type: 'state' | 'union_territory';
  capitalName?: string;
  capitalLat?: number;
  capitalLon?: number;
  languages: string[];
  aliases: string[];
  slug: string;
  districtCount: number;
}

export interface DistrictResponseDto {
  id: string; // lgd_code, e.g. 'IN-AP-01'
  stateCode: string;
  name: string;
  nameLocal?: Record<string, string>;
  aliases: string[];
  headquarters?: string;
  subdivisionType: string;
  slug: string;
}
