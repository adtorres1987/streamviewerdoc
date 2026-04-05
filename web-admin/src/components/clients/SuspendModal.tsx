'use client';

import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { useSuspendClient, useActivateClient } from '@/hooks/useClients';
import type { UserStatus } from '@/types';

interface SuspendModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  clientId: string;
  clientName: string;
  currentStatus: UserStatus;
}

export function SuspendModal({
  open,
  onOpenChange,
  clientId,
  clientName,
  currentStatus,
}: SuspendModalProps) {
  const isSuspended = currentStatus === 'suspended';
  const { mutate: suspend, isPending: suspending } = useSuspendClient();
  const { mutate: activate, isPending: activating } = useActivateClient();
  const isPending = suspending || activating;

  function handleConfirm() {
    const action = isSuspended ? activate : suspend;
    const successMsg = isSuspended ? 'Cliente activado' : 'Cliente suspendido';

    action(clientId, {
      onSuccess: () => {
        toast.success(successMsg);
        onOpenChange(false);
      },
      onError: (err) => {
        toast.error(err.message);
      },
    });
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {isSuspended ? 'Activar cliente' : 'Suspender cliente'}
          </DialogTitle>
          <DialogDescription>
            {isSuspended
              ? `Activar la cuenta de ${clientName}. Podra acceder a la app nuevamente.`
              : `Suspender la cuenta de ${clientName}. No podra iniciar sesion hasta ser reactivado.`}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
          >
            Cancelar
          </Button>
          <Button
            variant={isSuspended ? 'default' : 'destructive'}
            onClick={handleConfirm}
            disabled={isPending}
          >
            {isPending
              ? 'Procesando...'
              : isSuspended
              ? 'Activar'
              : 'Suspender'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
