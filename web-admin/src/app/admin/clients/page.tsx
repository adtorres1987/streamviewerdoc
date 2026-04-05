'use client';

import { useState, useEffect } from 'react';
import { useClients } from '@/hooks/useClients';
import { ClientsTable } from '@/components/clients/ClientsTable';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Search } from 'lucide-react';

function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);

  return debounced;
}

export default function ClientsPage() {
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('all');
  const debouncedSearch = useDebounce(search, 300);

  const { data, isLoading, isError, refetch } = useClients(
    debouncedSearch || undefined,
    status
  );

  const clients = data?.data ?? [];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold">Clientes</h2>
        <p className="text-muted-foreground">
          Gestiona los clientes de tu grupo
        </p>
      </div>

      <div className="flex flex-col gap-3 sm:flex-row">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            placeholder="Buscar por nombre o email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <Select value={status} onValueChange={setStatus}>
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="Todos los estados" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todos</SelectItem>
            <SelectItem value="active">Activo</SelectItem>
            <SelectItem value="suspended">Suspendido</SelectItem>
            <SelectItem value="pending">Pendiente</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isError ? (
        <div className="flex flex-col items-center gap-2 py-8 text-center">
          <p className="text-muted-foreground">Error al cargar los clientes</p>
          <button
            onClick={() => refetch()}
            className="text-sm text-primary underline"
          >
            Reintentar
          </button>
        </div>
      ) : (
        <ClientsTable clients={clients} isLoading={isLoading} />
      )}
    </div>
  );
}
