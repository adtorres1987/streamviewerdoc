export type UserRole = 'superadmin' | 'admin' | 'client';
export type UserStatus = 'pending' | 'active' | 'suspended';
export type SubscriptionStatus = 'trial' | 'active' | 'expired' | 'cancelled';
export type RoomStatus = 'waiting' | 'active' | 'host_disconnected' | 'closed';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  created_at: string;
  group_id?: string;
}

export interface Subscription {
  id: string;
  user_id: string;
  plan_id: string;
  status: SubscriptionStatus;
  trial_ends_at: string | null;
  current_period_start: string | null;
  current_period_end: string | null;
  cancel_at_period_end: boolean;
  stripe_customer_id: string | null;
  stripe_subscription_id: string | null;
  created_at: string;
}

export interface Room {
  id: string;
  name: string;
  host_id: string;
  group_id: string;
  status: RoomStatus;
  pdf_url: string;
  last_page: number;
  last_offset: number;
  host_disconnected_at: string | null;
  created_at: string;
  closed_at: string | null;
}

export interface Plan {
  id: string;
  name: string;
  price_usd: number;
  interval: 'month' | 'year';
  stripe_price_id: string;
  max_rooms: number;
  max_members_per_room: number;
  created_at: string;
}

export interface GlobalSettings {
  key: string;
  value: string;
  description: string | null;
  updated_at: string;
}

export interface MonthlyData {
  month: string;
  value: number;
}

export interface Metrics {
  mrr: number;
  total_users: number;
  churn_rate: number;
  total_admins: number;
  active_rooms: number;
  trial_users: number;
  active_subscriptions: number;
  expired_subscriptions: number;
  revenue_by_month: MonthlyData[];
  users_by_month: MonthlyData[];
}

export interface Group {
  id: string;
  name: string;
  admin_id: string;
  created_at: string;
  member_count?: number;
}

export interface ClientDetail extends User {
  subscription: Subscription | null;
  groups: Group[];
  recent_rooms: Room[];
}

export interface AdminUser extends User {
  client_count: number;
  invited_at: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
}
