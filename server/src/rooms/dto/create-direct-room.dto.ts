import { IsUUID } from 'class-validator';

export class CreateDirectRoomDto {
  @IsUUID()
  participantId!: string;
}
