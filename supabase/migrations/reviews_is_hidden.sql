-- Add is_hidden column to reviews for admin soft-hide functionality
alter table public.reviews
  add column if not exists is_hidden boolean not null default false;
