import { Controller, Post, Body, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { ContactsService } from './contacts.service';
import { SyncContactsDto } from './dto/sync-contacts.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@Controller('contacts')
@UseGuards(JwtAuthGuard)
export class ContactsController {
  constructor(private readonly contacts: ContactsService) {}

  /**
   * POST /contacts/sync
   * 클라이언트 연락처 SHA-256 해시 목록 → 링톡 가입자 매칭 → 친구 자동 등록
   *
   * Request : { phoneHashes: string[] }  (최대 500개)
   * Response: { matched: number, friends: UserPublicProfile[] }
   */
  @Post('sync')
  @HttpCode(HttpStatus.OK)
  syncContacts(
    @CurrentUser() user: JwtPayload,
    @Body() dto: SyncContactsDto,
  ) {
    return this.contacts.syncContacts(user.sub, dto.phoneHashes);
  }

}
