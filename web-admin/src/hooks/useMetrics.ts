import { useQuery } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { ApiResponse, Metrics } from '@/types';

export function useMetrics() {
  return useQuery({
    queryKey: ['metrics'],
    queryFn: () => api.get<ApiResponse<Metrics>>('/superadmin/metrics'),
  });
}

export function useActiveRooms() {
  return useQuery({
    queryKey: ['active-rooms'],
    queryFn: () => api.get<ApiResponse<unknown[]>>('/admin/rooms/active'),
    refetchInterval: 30_000,
  });
}
