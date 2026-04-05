'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { toast } from 'sonner';
import { FileText } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { useAuthStore } from '@/lib/auth';
import { api } from '@/lib/api';
import type { ApiResponse, User } from '@/types';

const schema = z.object({
  email: z.string().email('Email invalido'),
  password: z.string().min(1, 'La contrasena es requerida'),
});

type FormData = z.infer<typeof schema>;

interface LoginResponse {
  token: string;
  user: User;
}

export default function LoginPage() {
  const router = useRouter();
  const { user, token, setAuth } = useAuthStore();

  useEffect(() => {
    if (token && user) {
      router.replace(user.role === 'superadmin' ? '/superadmin' : '/admin');
    }
  }, [token, user, router]);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  async function onSubmit(data: FormData) {
    try {
      const res = await api.post<ApiResponse<LoginResponse>>('/auth/login', {
        email: data.email,
        password: data.password,
      });

      if (!res.success || !res.data) {
        throw new Error('Respuesta invalida del servidor');
      }

      const { token, user } = res.data;

      if (user.role === 'client') {
        toast.error('Acceso denegado. Solo admins pueden ingresar al panel.');
        return;
      }

      setAuth(user, token);
      toast.success(`Bienvenido, ${user.name || user.email}`);
      router.push(user.role === 'superadmin' ? '/superadmin' : '/admin');
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Error al iniciar sesion';
      toast.error(message);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/30 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1 text-center">
          <div className="flex justify-center">
            <div className="flex items-center gap-2">
              <FileText className="h-7 w-7 text-primary" />
              <span className="text-2xl font-bold">SyncPDF</span>
            </div>
          </div>
          <CardTitle className="text-xl">Panel de administracion</CardTitle>
          <p className="text-sm text-muted-foreground">
            Acceso exclusivo para admins y superadmins
          </p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="admin@syncpdf.app"
                autoComplete="email"
                {...register('email')}
              />
              {errors.email && (
                <p className="text-sm text-destructive">
                  {errors.email.message}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Contrasena</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                {...register('password')}
              />
              {errors.password && (
                <p className="text-sm text-destructive">
                  {errors.password.message}
                </p>
              )}
            </div>
            <Button type="submit" className="w-full" disabled={isSubmitting}>
              {isSubmitting ? 'Iniciando sesion...' : 'Iniciar sesion'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
