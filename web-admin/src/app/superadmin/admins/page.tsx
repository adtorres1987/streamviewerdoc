'use client';

import { useState } from 'react';
import { UserPlus } from 'lucide-react';
import { useAdmins } from '@/hooks/useAdmins';
import { AdminsTable } from '@/components/admins/AdminsTable';
import { InviteAdminModal } from '@/components/admins/InviteAdminModal';
import { Button } from '@/components/ui/button';

export default function AdminsPage() {
  const [inviteOpen, setInviteOpen] = useState(false);
  const { data, isLoading, isError, refetch } = useAdmins();
  const admins = data?.data ?? [];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Administradores</h2>
          <p className="text-muted-foreground">
            Gestiona los admins del sistema
          </p>
        </div>
        <Button onClick={() => setInviteOpen(true)}>
          <UserPlus className="mr-2 h-4 w-4" />
          Invitar admin
        </Button>
      </div>

      {isError ? (
        <div className="flex flex-col items-center gap-2 py-8 text-center">
          <p className="text-muted-foreground">Error al cargar los admins</p>
          <button
            onClick={() => refetch()}
            className="text-sm text-primary underline"
          >
            Reintentar
          </button>
        </div>
      ) : (
        <AdminsTable admins={admins} isLoading={isLoading} />
      )}

      <InviteAdminModal open={inviteOpen} onOpenChange={setInviteOpen} />
    </div>
  );
}
