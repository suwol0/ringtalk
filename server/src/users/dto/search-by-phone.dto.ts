import { IsArray, IsString } from 'class-validator';

export class SearchByPhoneDto {
  @IsArray()
  @IsString({ each: true })
  phoneHashes!: string[];
}
