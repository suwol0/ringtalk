import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  @MaxLength(20)
  @IsOptional()
  displayName?: string;

  @IsString()
  @MaxLength(60)
  @IsOptional()
  statusMessage?: string;
}
