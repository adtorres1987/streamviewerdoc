'use client';

import { useMetrics } from '@/hooks/useMetrics';
import { StatsCards } from '@/components/metrics/StatsCards';
import { RevenueChart } from '@/components/metrics/RevenueChart';
import { UsersGrowthChart } from '@/components/metrics/UsersGrowthChart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

export default function MetricsPage() {
  const { data, isLoading, isError } = useMetrics();
  const metrics = data?.data;

  if (isError) {
    return (
      <div className="rounded-lg border border-destructive/50 bg-destructive/10 p-4 text-sm text-destructive">
        Error al cargar las metricas. Verifica que el backend este disponible.
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Metricas</h2>
        <p className="text-muted-foreground">
          Analisis de crecimiento e ingresos
        </p>
      </div>

      <StatsCards metrics={metrics} isLoading={isLoading} />

      <div className="grid gap-4 md:grid-cols-2">
        <RevenueChart
          data={metrics?.revenue_by_month}
          isLoading={isLoading}
        />
        <UsersGrowthChart
          data={metrics?.users_by_month}
          isLoading={isLoading}
        />
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Retencion</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-12 w-full" />
            ) : (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">
                    Tasa de retencion
                  </span>
                  <span className="text-lg font-bold">
                    {metrics
                      ? `${(100 - (metrics.churn_rate ?? 0)).toFixed(1)}%`
                      : '—'}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">
                    Churn mensual
                  </span>
                  <span className="text-lg font-bold text-destructive">
                    {metrics ? `${(metrics.churn_rate ?? 0).toFixed(1)}%` : '—'}
                  </span>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Suscripciones</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-12 w-full" />
            ) : (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">
                    Activas
                  </span>
                  <span className="text-lg font-bold">
                    {metrics?.active_subscriptions ?? 0}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">
                    En trial
                  </span>
                  <span className="text-lg font-bold">
                    {metrics?.trial_users ?? 0}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">
                    Expiradas
                  </span>
                  <span className="text-lg font-bold text-muted-foreground">
                    {metrics?.expired_subscriptions ?? 0}
                  </span>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
