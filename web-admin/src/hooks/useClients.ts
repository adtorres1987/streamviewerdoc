import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { ApiResponse, User, ClientDetail } from '@/types';

export function useClients(search?: string, status?: string) {
  const params = new URLSearchParams();
  if (search) params.set('q', search);
  if (status && status !== 'all') params.set('status', status);
  const query = params.toString();

  return useQuery({
    queryKey: ['clients', search, status],
    queryFn: () =>
      api.get<ApiResponse<User[]>>(`/admin/clients${query ? `?${query}` : ''}`),
  });
}

export function useClient(id: string) {
  return useQuery({
    queryKey: ['clients', id],
    queryFn: () => api.get<ApiResponse<ClientDetail>>(`/admin/clients/${id}`),
    enabled: !!id,
  });
}

export function useSuspendClient() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.patch(`/admin/clients/${id}/suspend`, {}),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });
}

export function useActivateClient() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.patch(`/admin/clients/${id}/activate`, {}),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });
}

export function useEditTrial() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, trial_days }: { id: string; trial_days: number }) =>
      api.patch(`/admin/clients/${id}/trial`, { trial_days }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });
}
