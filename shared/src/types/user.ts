// 유저 관련 타입 정의

export type UserStatus = 'active' | 'inactive' | 'blocked' | 'withdrawn';
export type FriendStatus = 'pending' | 'accepted' | 'blocked';
export type Presence = 'online' | 'offline' | 'away';

export interface User {
  id: string;
  phoneNumber: string; // 해시된 상태로 저장, 클라이언트에 노출 안 됨
  displayName: string;
  profileImageUrl?: string;
  statusMessage?: string;
  status: UserStatus;
  presence: Presence;
  lastSeenAt?: string; // ISO 8601
  createdAt: string;
  updatedAt: string;
}

export interface UserPublicProfile {
  id: string;
  displayName: string;
  profileImageUrl?: string;
  statusMessage?: string;
  phoneHash?: string; // 연락처 매칭용 (클라이언트 역방향 맵핑)
  presence?: Presence;
  lastSeenAt?: string;
}

export interface Friend {
  id: string;
  userId: string;
  friendId: string;
  status: FriendStatus;
  alias?: string; // 내가 설정한 별명
  createdAt: string;
  friend: UserPublicProfile;
}

export interface UpdateProfileDto {
  displayName?: string;
  statusMessage?: string;
}
