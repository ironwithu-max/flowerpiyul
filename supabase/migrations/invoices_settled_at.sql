-- Add settled_at column to invoices for settlement tracking
alter table public.invoices
  add column if not exists settled_at timestamptz;
