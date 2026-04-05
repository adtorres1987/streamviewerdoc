'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Calendar, Mail, User } from 'lucide-react';
import { useClient } from '@/hooks/useClients';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { Badge } from '@/components/ui/badge';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { ClientStatusBadge } from '@/components/clients/ClientStatusBadge';
import { EditTrialModal } from '@/components/clients/EditTrialModal';
import { SuspendModal } from '@/components/clients/SuspendModal';
import { formatDate, getDaysRemaining, formatCurrency } from '@/lib/utils';

export default function ClientDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const { data, isLoading, isError } = useClient(id);
  const [editTrialOpen, setEditTrialOpen] = useState(false);
  const [suspendOpen, setSuspendOpen] = useState(false);

  const client = data?.data;

  if (isLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <div className="grid gap-4 md:grid-cols-2">
          <Skeleton className="h-40 w-full" />
          <Skeleton className="h-40 w-full" />
        </div>
      </div>
    );
  }

  if (isError || !client) {
    return (
      <div className="flex flex-col items-center gap-4 py-16 text-center">
        <p className="text-muted-foreground">No se pudo cargar el cliente</p>
        <Button variant="outline" onClick={() => router.back()}>
          Volver
        </Button>
      </div>
    );
  }

  const trialDaysRemaining = client.subscription?.trial_ends_at
    ? getDaysRemaining(client.subscription.trial_ends_at)
    : null;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Button
          variant="ghost"
          size="icon"
          onClick={() => router.back()}
        >
          <ArrowLeft className="h-4 w-4" />
        </Button>
        <div>
          <h2 className="text-2xl font-bold">{client.name}</h2>
          <p className="text-muted-foreground">Detalle del cliente</p>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {/* User Info */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Informacion del usuario</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-2 text-sm">
              <User className="h-4 w-4 text-muted-foreground" />
              <span>{client.name}</span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <Mail className="h-4 w-4 text-muted-foreground" />
              <span>{client.email}</span>
            </div>
            <div className="flex items-center gap-2 text-sm">
              <Calendar className="h-4 w-4 text-muted-foreground" />
              <span>Registro: {formatDate(client.created_at)}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-sm text-muted-foreground">Estado:</span>
              <ClientStatusBadge
                userStatus={client.status}
                subscriptionStatus={client.subscription?.status}
              />
            </div>
          </CardContent>
        </Card>

        {/* Subscription Info */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Suscripcion</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {client.subscription ? (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Estado</span>
                  <Badge
                    variant={
                      client.subscription.status === 'active'
                        ? 'success'
                        : client.subscription.status === 'trial'
                        ? 'warning'
                        : 'destructive'
                    }
                  >
                    {client.subscription.status}
                  </Badge>
                </div>
                {trialDaysRemaining !== null && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">
                      Dias de trial restantes
                    </span>
                    <span className="text-sm font-medium">
                      {trialDaysRemaining}
                    </span>
                  </div>
                )}
                {client.subscription.current_period_end && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">
                      Proximo cobro
                    </span>
                    <span className="text-sm">
                      {formatDate(client.subscription.current_period_end)}
                    </span>
                  </div>
                )}
                {client.subscription.stripe_customer_id && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">
                      Stripe ID
                    </span>
                    <span className="text-xs font-mono text-muted-foreground">
                      {client.subscription.stripe_customer_id}
                    </span>
                  </div>
                )}
              </>
            ) : (
              <p className="text-sm text-muted-foreground">
                Sin suscripcion activa
              </p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Actions */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Acciones</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-3">
          <Button
            variant="outline"
            onClick={() => setEditTrialOpen(true)}
          >
            Editar dias de trial
          </Button>
          <Button
            variant={client.status === 'suspended' ? 'default' : 'destructive'}
            onClick={() => setSuspendOpen(true)}
          >
            {client.status === 'suspended' ? 'Activar cuenta' : 'Suspender cuenta'}
          </Button>
        </CardContent>
      </Card>

      {/* Groups */}
      {client.groups && client.groups.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Grupos</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Nombre</TableHead>
                  <TableHead>Miembros</TableHead>
                  <TableHead>Creacion</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {client.groups.map((group) => (
                  <TableRow key={group.id}>
                    <TableCell className="font-medium">{group.name}</TableCell>
                    <TableCell>{group.member_count ?? '—'}</TableCell>
                    <TableCell className="text-muted-foreground">
                      {formatDate(group.created_at)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      {/* Recent Rooms */}
      {client.recent_rooms && client.recent_rooms.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Salas recientes</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Nombre</TableHead>
                  <TableHead>Estado</TableHead>
                  <TableHead>Creacion</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {client.recent_rooms.map((room) => (
                  <TableRow key={room.id}>
                    <TableCell className="font-medium">{room.name}</TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          room.status === 'active' ? 'success' : 'secondary'
                        }
                      >
                        {room.status}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {formatDate(room.created_at)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}

      <EditTrialModal
        open={editTrialOpen}
        onOpenChange={setEditTrialOpen}
        clientId={client.id}
        clientName={client.name}
        currentDays={trialDaysRemaining ?? undefined}
      />
      <SuspendModal
        open={suspendOpen}
        onOpenChange={setSuspendOpen}
        clientId={client.id}
        clientName={client.name}
        currentStatus={client.status}
      />
    </div>
  );
}
