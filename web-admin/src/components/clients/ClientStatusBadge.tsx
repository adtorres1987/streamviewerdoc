import { Badge } from '@/components/ui/badge';
import type { UserStatus, SubscriptionStatus } from '@/types';

interface ClientStatusBadgeProps {
  userStatus: UserStatus;
  subscriptionStatus?: SubscriptionStatus | null;
}

export function ClientStatusBadge({
  userStatus,
  subscriptionStatus,
}: ClientStatusBadgeProps) {
  if (userStatus === 'suspended') {
    return <Badge variant="destructive">Suspendido</Badge>;
  }

  if (userStatus === 'pending') {
    return <Badge variant="outline">Pendiente</Badge>;
  }

  if (!subscriptionStatus) {
    return <Badge variant="secondary">Sin suscripcion</Badge>;
  }

  switch (subscriptionStatus) {
    case 'trial':
      return <Badge variant="warning">Trial</Badge>;
    case 'active':
      return <Badge variant="success">Activo</Badge>;
    case 'expired':
      return <Badge variant="destructive">Expirado</Badge>;
    case 'cancelled':
      return <Badge variant="outline">Cancelado</Badge>;
    default:
      return <Badge variant="secondary">{subscriptionStatus}</Badge>;
  }
}
