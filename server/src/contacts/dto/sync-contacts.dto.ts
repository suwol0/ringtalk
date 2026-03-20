import { IsArray, IsString, ArrayMaxSize } from 'class-validator';

export class SyncContactsDto {
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(500, { message: '한 번에 최대 500개까지 전송 가능합니다.' })
  phoneHashes!: string[];
}
