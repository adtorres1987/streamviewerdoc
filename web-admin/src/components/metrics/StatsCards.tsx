import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { formatCurrency } from '@/lib/utils';
import type { Metrics } from '@/types';

interface StatsCardsProps {
  metrics: Metrics | undefined;
  isLoading: boolean;
}

interface StatCardProps {
  title: string;
  value: string | number;
  description?: string;
}

function StatCard({ title, value, description }: StatCardProps) {
  return (
    <Card>
      <CardHeader className="pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {description && (
          <p className="mt-1 text-xs text-muted-foreground">{description}</p>
        )}
      </CardContent>
    </Card>
  );
}

export function StatsCards({ metrics, isLoading }: StatsCardsProps) {
  if (isLoading) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 4 }).map((_, i) => (
          <Card key={i}>
            <CardHeader className="pb-2">
              <Skeleton className="h-4 w-24" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-16" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  if (!metrics) return null;

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="MRR"
        value={formatCurrency(metrics.mrr)}
        description="Ingresos mensuales recurrentes"
      />
      <StatCard
        title="Usuarios totales"
        value={metrics.total_users}
        description={`${metrics.trial_users} en trial`}
      />
      <StatCard
        title="Churn rate"
        value={`${(metrics.churn_rate ?? 0).toFixed(1)}%`}
        description="Tasa de cancelacion mensual"
      />
      <StatCard
        title="Admins"
        value={metrics.total_admins}
        description="Administradores activos"
      />
    </div>
  );
}
