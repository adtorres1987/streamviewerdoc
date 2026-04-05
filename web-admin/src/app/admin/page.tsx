'use client';

import { useClients } from '@/hooks/useClients';
import { useActiveRooms } from '@/hooks/useMetrics';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Users, UserCheck, UserX, MonitorPlay } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: number | string;
  icon: React.ReactNode;
  description?: string;
  isLoading: boolean;
}

function StatCard({ title, value, icon, description, isLoading }: StatCardProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <div className="text-muted-foreground">{icon}</div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <Skeleton className="h-8 w-16" />
        ) : (
          <>
            <div className="text-2xl font-bold">{value}</div>
            {description && (
              <p className="mt-1 text-xs text-muted-foreground">{description}</p>
            )}
          </>
        )}
      </CardContent>
    </Card>
  );
}

export default function AdminDashboardPage() {
  const { data: clientsData, isLoading: clientsLoading } = useClients();
  const { data: roomsData, isLoading: roomsLoading } = useActiveRooms();

  const clients = clientsData?.data ?? [];
  const activeRooms = roomsData?.data ?? [];

  const trialCount = clients.filter(
    (c) => c.status === 'active'
  ).length;

  // We use the raw count since sub status is not part of the list view
  const totalClients = clients.length;
  const suspended = clients.filter((c) => c.status === 'suspended').length;
  const active = clients.filter((c) => c.status === 'active').length;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Dashboard</h2>
        <p className="text-muted-foreground">Resumen de tu grupo de clientes</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total clientes"
          value={totalClients}
          icon={<Users className="h-4 w-4" />}
          description="Registrados en tu grupo"
          isLoading={clientsLoading}
        />
        <StatCard
          title="Activos"
          value={active}
          icon={<UserCheck className="h-4 w-4" />}
          description="Cuentas activas"
          isLoading={clientsLoading}
        />
        <StatCard
          title="Suspendidos"
          value={suspended}
          icon={<UserX className="h-4 w-4" />}
          description="Cuentas suspendidas"
          isLoading={clientsLoading}
        />
        <StatCard
          title="Salas activas"
          value={activeRooms.length}
          icon={<MonitorPlay className="h-4 w-4" />}
          description="Sesiones en curso ahora"
          isLoading={roomsLoading}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Salas activas ahora</CardTitle>
        </CardHeader>
        <CardContent>
          {roomsLoading ? (
            <Skeleton className="h-8 w-full" />
          ) : activeRooms.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No hay salas activas en este momento
            </p>
          ) : (
            <p className="text-sm text-muted-foreground">
              <span className="text-2xl font-bold text-foreground">
                {activeRooms.length}
              </span>{' '}
              {activeRooms.length === 1 ? 'sala activa' : 'salas activas'}
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
