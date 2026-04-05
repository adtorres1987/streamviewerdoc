'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useEditTrial } from '@/hooks/useClients';

const schema = z.object({
  trial_days: z.coerce
    .number()
    .int()
    .min(1, 'Minimo 1 dia')
    .max(365, 'Maximo 365 dias'),
});

type FormData = z.infer<typeof schema>;

interface EditTrialModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  clientId: string;
  clientName: string;
  currentDays?: number;
}

export function EditTrialModal({
  open,
  onOpenChange,
  clientId,
  clientName,
  currentDays,
}: EditTrialModalProps) {
  const { mutate, isPending } = useEditTrial();

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { trial_days: currentDays ?? 15 },
  });

  useEffect(() => {
    if (open) reset({ trial_days: currentDays ?? 15 });
  }, [open, currentDays, reset]);

  function onSubmit(data: FormData) {
    mutate(
      { id: clientId, trial_days: data.trial_days },
      {
        onSuccess: () => {
          toast.success('Dias de trial actualizados');
          onOpenChange(false);
        },
        onError: (err) => {
          toast.error(err.message);
        },
      }
    );
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Editar Trial</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Cliente: <span className="font-medium text-foreground">{clientName}</span>
          </p>
          <div className="space-y-2">
            <Label htmlFor="trial_days">Dias de trial</Label>
            <Input
              id="trial_days"
              type="number"
              min={1}
              max={365}
              {...register('trial_days')}
            />
            {errors.trial_days && (
              <p className="text-sm text-destructive">
                {errors.trial_days.message}
              </p>
            )}
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancelar
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending ? 'Guardando...' : 'Guardar'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
