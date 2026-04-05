'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  Settings,
  BarChart3,
  UserCog,
  FileText,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuthStore } from '@/lib/auth';

interface NavItem {
  href: string;
  label: string;
  icon: React.ReactNode;
}

const adminNavItems: NavItem[] = [
  {
    href: '/admin',
    label: 'Dashboard',
    icon: <LayoutDashboard className="h-4 w-4" />,
  },
  {
    href: '/admin/clients',
    label: 'Clientes',
    icon: <Users className="h-4 w-4" />,
  },
];

const superadminNavItems: NavItem[] = [
  {
    href: '/superadmin',
    label: 'Dashboard',
    icon: <LayoutDashboard className="h-4 w-4" />,
  },
  {
    href: '/admin',
    label: 'Mis Clientes',
    icon: <Users className="h-4 w-4" />,
  },
  {
    href: '/superadmin/admins',
    label: 'Admins',
    icon: <UserCog className="h-4 w-4" />,
  },
  {
    href: '/superadmin/metrics',
    label: 'Metricas',
    icon: <BarChart3 className="h-4 w-4" />,
  },
  {
    href: '/superadmin/settings',
    label: 'Configuracion',
    icon: <Settings className="h-4 w-4" />,
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const user = useAuthStore((s) => s.user);

  const navItems =
    user?.role === 'superadmin' ? superadminNavItems : adminNavItems;

  return (
    <aside className="flex h-full w-64 flex-col border-r bg-card">
      <div className="flex h-16 items-center border-b px-6">
        <FileText className="h-5 w-5 text-primary" />
        <span className="ml-2 text-lg font-semibold">SyncPDF</span>
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {navItems.map((item) => {
          const isActive =
            item.href === '/admin' || item.href === '/superadmin'
              ? pathname === item.href
              : pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              )}
            >
              {item.icon}
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="border-t p-4">
        <div className="text-xs text-muted-foreground">
          <span className="font-medium capitalize">{user?.role}</span>
          <p className="mt-0.5 truncate">{user?.email}</p>
        </div>
      </div>
    </aside>
  );
}
