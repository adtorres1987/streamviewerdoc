'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { useSettings, useUpdateSettings } from '@/hooks/useSettings';
import { usePlans, useUpdatePlan } from '@/hooks/usePlans';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { formatCurrency } from '@/lib/utils';
import type { Plan } from '@/types';

const settingsSchema = z.object({
  default_trial_days: z.coerce
    .number()
    .int()
    .min(1, 'Minimo 1 dia')
    .max(365, 'Maximo 365 dias'),
});

type SettingsFormData = z.infer<typeof settingsSchema>;

const planSchema = z.object({
  price_usd: z.coerce.number().min(0.01, 'El precio debe ser mayor a 0'),
});

type PlanFormData = z.infer<typeof planSchema>;

function EditablePlanRow({ plan }: { plan: Plan }) {
  const [editing, setEditing] = useState(false);
  const { mutate, isPending } = useUpdatePlan();

  const { register, handleSubmit, reset, formState: { errors } } = useForm<PlanFormData>({
    resolver: zodResolver(planSchema),
    defaultValues: { price_usd: plan.price_usd },
  });

  function onSubmit(data: PlanFormData) {
    mutate(
      { id: plan.id, price_usd: data.price_usd },
      {
        onSuccess: () => {
          toast.success(`Plan ${plan.name} actualizado`);
          setEditing(false);
        },
        onError: (err) => toast.error(err.message),
      }
    );
  }

  return (
    <TableRow>
      <TableCell className="font-medium">{plan.name}</TableCell>
      <TableCell className="capitalize">{plan.interval === 'month' ? 'Mensual' : 'Anual'}</TableCell>
      <TableCell>
        {editing ? (
          <form onSubmit={handleSubmit(onSubmit)} className="flex items-center gap-2">
            <div>
              <Input
                type="number"
                step="0.01"
                min="0.01"
                className="w-28"
                {...register('price_usd')}
              />
              {errors.price_usd && (
                <p className="text-xs text-destructive">{errors.price_usd.message}</p>
              )}
            </div>
            <Button type="submit" size="sm" disabled={isPending}>
              {isPending ? 'Guardando...' : 'Guardar'}
            </Button>
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={() => {
                reset({ price_usd: plan.price_usd });
                setEditing(false);
              }}
            >
              Cancelar
            </Button>
          </form>
        ) : (
          <div className="flex items-center gap-2">
            <span>{formatCurrency(plan.price_usd)}</span>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setEditing(true)}
            >
              Editar
            </Button>
          </div>
        )}
      </TableCell>
      <TableCell className="text-muted-foreground text-xs font-mono">
        {plan.stripe_price_id}
      </TableCell>
    </TableRow>
  );
}

export default function SettingsPage() {
  const { data: settingsData, isLoading: settingsLoading } = useSettings();
  const { data: plansData, isLoading: plansLoading } = usePlans();
  const { mutate: updateSettings, isPending: savingSettings } = useUpdateSettings();

  // Backend returns settings as an object { key: value }, not an array
  const settings = settingsData?.data as Record<string, string> | undefined;
  const plans = plansData?.data ?? [];

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<SettingsFormData>({
    resolver: zodResolver(settingsSchema),
    values: {
      default_trial_days: settings?.default_trial_days
        ? parseInt(settings.default_trial_days, 10)
        : 15,
    },
  });

  function onSubmitSettings(data: SettingsFormData) {
    updateSettings(
      { key: 'default_trial_days', value: String(data.default_trial_days) },
      {
        onSuccess: () => toast.success('Configuracion guardada'),
        onError: (err) => toast.error(err.message),
      }
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Configuracion</h2>
        <p className="text-muted-foreground">
          Ajustes globales del sistema
        </p>
      </div>

      {/* Global Settings */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Configuracion general</CardTitle>
        </CardHeader>
        <CardContent>
          {settingsLoading ? (
            <div className="space-y-4">
              <Skeleton className="h-8 w-48" />
              <Skeleton className="h-10 w-32" />
            </div>
          ) : (
            <form onSubmit={handleSubmit(onSubmitSettings)} className="space-y-4 max-w-sm">
              <div className="space-y-2">
                <Label htmlFor="default_trial_days">
                  Dias de trial por defecto
                </Label>
                <Input
                  id="default_trial_days"
                  type="number"
                  min={1}
                  max={365}
                  {...register('default_trial_days')}
                />
                {errors.default_trial_days && (
                  <p className="text-sm text-destructive">
                    {errors.default_trial_days.message}
                  </p>
                )}
                <p className="text-xs text-muted-foreground">
                  Numero de dias de trial que reciben los nuevos usuarios al registrarse
                </p>
              </div>
              <Button type="submit" disabled={savingSettings}>
                {savingSettings ? 'Guardando...' : 'Guardar configuracion'}
              </Button>
            </form>
          )}
        </CardContent>
      </Card>

      {/* Plans */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Planes de suscripcion</CardTitle>
        </CardHeader>
        <CardContent>
          {plansLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 2 }).map((_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : plans.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No hay planes configurados
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Plan</TableHead>
                  <TableHead>Periodo</TableHead>
                  <TableHead>Precio</TableHead>
                  <TableHead>Stripe Price ID</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {plans.map((plan) => (
                  <EditablePlanRow key={plan.id} plan={plan} />
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
