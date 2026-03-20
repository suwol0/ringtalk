import { IsString, Matches, Length, IsIn, IsOptional } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, { message: '전화번호는 E.164 형식이어야 합니다.' })
  phoneNumber!: string;

  @IsString()
  @Length(6, 6, { message: 'OTP는 6자리여야 합니다.' })
  otp!: string;

  @IsString()
  deviceId!: string;

  @IsString()
  deviceName!: string;

  @IsIn(['ios', 'android', 'windows', 'macos', 'web'])
  platform!: string;

  @IsString()
  @IsOptional()
  pushToken?: string;
}
