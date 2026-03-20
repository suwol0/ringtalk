import { Controller, Get, Patch, Post, Body, Param, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { SearchByPhoneDto } from './dto/search-by-phone.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get('me')
  getMe(@CurrentUser() user: JwtPayload) {
    return this.users.getMe(user.sub);
  }

  @Patch('me')
  updateProfile(@CurrentUser() user: JwtPayload, @Body() dto: UpdateProfileDto) {
    return this.users.updateProfile(user.sub, dto);
  }

  @Get('me/friends')
  getFriends(@CurrentUser() user: JwtPayload) {
    return this.users.getFriends(user.sub);
  }

  @Post('search')
  @HttpCode(HttpStatus.OK)
  searchByPhone(@Body() dto: SearchByPhoneDto) {
    return this.users.searchByPhoneHash(dto.phoneHashes);
  }

  @Post(':id/block')
  @HttpCode(HttpStatus.NO_CONTENT)
  async blockUser(@CurrentUser() user: JwtPayload, @Param('id') targetId: string) {
    await this.users.blockUser(user.sub, targetId);
  }
}
