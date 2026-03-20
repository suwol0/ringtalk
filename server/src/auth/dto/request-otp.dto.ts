import { IsString, Matches, IsIn } from 'class-validator';

export class RequestOtpDto {
  @IsString()
  @Matches(/^\+[1-9]\d{7,14}$/, { message: '전화번호는 E.164 형식이어야 합니다. 예: +821012345678' })
  phoneNumber!: string;

  @IsString()
  deviceId!: string;

  @IsIn(['ios', 'android', 'windows', 'macos', 'web'])
  platform!: string;
}
