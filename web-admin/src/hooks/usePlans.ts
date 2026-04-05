import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { ApiResponse, Plan } from '@/types';

export function usePlans() {
  return useQuery({
    queryKey: ['plans'],
    queryFn: () => api.get<ApiResponse<Plan[]>>('/payments/plans'),
  });
}

export function useUpdatePlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      name,
      price_usd,
    }: {
      id: string;
      name?: string;
      price_usd?: number;
    }) => api.patch(`/payments/plans/${id}`, { name, price_usd }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['plans'] });
    },
  });
}
