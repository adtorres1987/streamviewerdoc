'use client';

import { useState } from 'react';
import { MoreHorizontal } from 'lucide-react';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from '@/components/ui/dialog';
import { Skeleton } from '@/components/ui/skeleton';
import { formatDate } from '@/lib/utils';
import { useSuspendAdmin, useActivateAdmin } from '@/hooks/useAdmins';
import { toast } from 'sonner';
import type { AdminUser } from '@/types';

interface AdminsTableProps {
  admins: AdminUser[];
  isLoading: boolean;
}

export function AdminsTable({ admins, isLoading }: AdminsTableProps) {
  const [confirmModal, setConfirmModal] = useState<{
    open: boolean;
    adminId: string;
    adminName: string;
    isSuspended: boolean;
  } | null>(null);

  const { mutate: suspend, isPending: suspending } = useSuspendAdmin();
  const { mutate: activate, isPending: activating } = useActivateAdmin();

  function handleConfirm() {
    if (!confirmModal) return;
    const action = confirmModal.isSuspended ? activate : suspend;
    const msg = confirmModal.isSuspended ? 'Admin activado' : 'Admin suspendido';

    action(confirmModal.adminId, {
      onSuccess: () => {
        toast.success(msg);
        setConfirmModal(null);
      },
      onError: (err) => toast.error(err.message),
    });
  }

  if (isLoading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-12 w-full" />
        ))}
      </div>
    );
  }

  if (admins.length === 0) {
    return (
      <div className="flex h-32 items-center justify-center text-muted-foreground">
        No hay administradores registrados
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
            <TableHead>Clientes</TableHead>
            <TableHead>Fecha invitacion</TableHead>
            <TableHead className="w-[80px]">Acciones</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {admins.map((admin) => (
            <TableRow key={admin.id}>
              <TableCell className="font-medium">{admin.name}</TableCell>
              <TableCell className="text-muted-foreground">
                {admin.email}
              </TableCell>
              <TableCell>
                {admin.status === 'suspended' ? (
                  <Badge variant="destructive">Suspendido</Badge>
                ) : admin.status === 'pending' ? (
                  <Badge variant="outline">Pendiente</Badge>
                ) : (
                  <Badge variant="success">Activo</Badge>
                )}
              </TableCell>
              <TableCell>{admin.client_count ?? 0}</TableCell>
              <TableCell className="text-muted-foreground">
                {formatDate(admin.invited_at || admin.created_at)}
              </TableCell>
              <TableCell>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon">
                      <MoreHorizontal className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem
                      onClick={() =>
                        setConfirmModal({
                          open: true,
                          adminId: admin.id,
                          adminName: admin.name,
                          isSuspended: admin.status === 'suspended',
                        })
                      }
                      className={
                        admin.status === 'suspended'
                          ? 'text-green-600'
                          : 'text-destructive'
                      }
                    >
                      {admin.status === 'suspended' ? 'Activar' : 'Suspender'}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      {confirmModal && (
        <Dialog
          open={confirmModal.open}
          onOpenChange={(open) => setConfirmModal(open ? confirmModal : null)}
        >
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle>
                {confirmModal.isSuspended
                  ? 'Activar administrador'
                  : 'Suspender administrador'}
              </DialogTitle>
              <DialogDescription>
                {confirmModal.isSuspended
                  ? `Activar la cuenta de ${confirmModal.adminName}.`
                  : `Suspender la cuenta de ${confirmModal.adminName}. No podra acceder al panel.`}
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setConfirmModal(null)}
              >
                Cancelar
              </Button>
              <Button
                variant={confirmModal.isSuspended ? 'default' : 'destructive'}
                onClick={handleConfirm}
                disabled={suspending || activating}
              >
                {suspending || activating
                  ? 'Procesando...'
                  : confirmModal.isSuspended
                  ? 'Activar'
                  : 'Suspender'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </>
  );
}
