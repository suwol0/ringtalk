import { IsString, IsNotEmpty, IsIn, IsInt, Min, Max } from 'class-validator';

export const ALLOWED_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'video/mp4',
  'video/quicktime',
  'application/pdf',
] as const;

export type AllowedContentType = (typeof ALLOWED_CONTENT_TYPES)[number];

const MAX_FILE_SIZE_BYTES = 100 * 1024 * 1024; // 100 MB

export class GetUploadUrlDto {
  @IsString()
  @IsNotEmpty()
  fileName!: string;

  @IsString()
  @IsIn(ALLOWED_CONTENT_TYPES, {
    message: `contentType은 다음 중 하나여야 합니다: ${ALLOWED_CONTENT_TYPES.join(', ')}`,
  })
  contentType!: AllowedContentType;

  @IsInt()
  @Min(1, { message: '파일 크기는 1 바이트 이상이어야 합니다.' })
  @Max(MAX_FILE_SIZE_BYTES, { message: '파일 크기는 100 MB를 초과할 수 없습니다.' })
  fileSize!: number;
}
