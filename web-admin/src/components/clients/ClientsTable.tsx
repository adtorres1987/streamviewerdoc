'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Eye, MoreHorizontal } from 'lucide-react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Skeleton } from '@/components/ui/skeleton';
import { ClientStatusBadge } from './ClientStatusBadge';
import { SuspendModal } from './SuspendModal';
import { formatDate, getDaysRemaining } from '@/lib/utils';
import type { User } from '@/types';

interface ClientsTableProps {
  clients: User[];
  isLoading: boolean;
}

export function ClientsTable({ clients, isLoading }: ClientsTableProps) {
  const [suspendModal, setSuspendModal] = useState<{
    open: boolean;
    clientId: string;
    clientName: string;
    status: User['status'];
  } | null>(null);

  if (isLoading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} className="h-12 w-full" />
        ))}
      </div>
    );
  }

  if (clients.length === 0) {
    return (
      <div className="flex h-32 items-center justify-center text-muted-foreground">
        No se encontraron clientes
      </div>
    );
  }

  return (
    <>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Nombre</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Estado</TableHead>
            <TableHead>Registro</TableHead>
            <TableHead className="w-[100px]">Acciones</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {clients.map((client) => (
            <TableRow key={client.id}>
              <TableCell className="font-medium">{client.name}</TableCell>
              <TableCell className="text-muted-foreground">
                {client.email}
              </TableCell>
              <TableCell>
                <ClientStatusBadge userStatus={client.status} />
              </TableCell>
              <TableCell className="text-muted-foreground">
                {formatDate(client.created_at)}
              </TableCell>
              <TableCell>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon">
                      <MoreHorizontal className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem asChild>
                      <Link href={`/admin/clients/${client.id}`}>
                        <Eye className="mr-2 h-4 w-4" />
                        Ver detalle
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      onClick={() =>
                        setSuspendModal({
                          open: true,
                          clientId: client.id,
                          clientName: client.name,
                          status: client.status,
                        })
                      }
                      className={
                        client.status === 'suspended'
                          ? 'text-green-600'
                          : 'text-destructive'
                      }
                    >
                      {client.status === 'suspended' ? 'Activar' : 'Suspender'}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {suspendModal && (
        <SuspendModal
          open={suspendModal.open}
          onOpenChange={(open) =>
            setSuspendModal(open ? suspendModal : null)
          }
          clientId={suspendModal.clientId}
          clientName={suspendModal.clientName}
          currentStatus={suspendModal.status}
        />
      )}
    </>
  );
}
