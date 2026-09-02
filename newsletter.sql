-- ============================================================
-- Visitando Tandil · Newsletter
-- Pegar en Supabase → SQL Editor → Run. Seguro de re-ejecutar.
-- ============================================================

create table if not exists public.subscribers (
  id          bigint generated always as identity primary key,
  email       text not null,
  source      text default 'popup',        -- de dónde vino: popup, pie, etc.
  created_at  timestamptz not null default now(),
  unsubscribed boolean not null default false
);

-- Un mismo correo no se guarda dos veces
create unique index if not exists subscribers_email_key
  on public.subscribers (lower(email));

alter table public.subscribers enable row level security;

-- Cualquiera puede anotarse desde el sitio…
drop policy if exists "anotarse" on public.subscribers;
create policy "anotarse" on public.subscribers
  for insert to anon, authenticated
  with check (true);

-- …pero la lista solo la ve el admin.
drop policy if exists "solo admin lee" on public.subscribers;
create policy "solo admin lee" on public.subscribers
  for select to authenticated
  using (public.is_admin());

drop policy if exists "solo admin edita" on public.subscribers;
create policy "solo admin edita" on public.subscribers
  for update to authenticated
  using (public.is_admin());

-- Resumen para el panel: total, últimos 30 días y últimos 7
create or replace function public.subscribers_stats()
returns table(total bigint, last30 bigint, last7 bigint)
language sql security definer set search_path = public as $$
  select
    count(*)::bigint,
    count(*) filter (where created_at >= now() - interval '30 days')::bigint,
    count(*) filter (where created_at >= now() - interval '7 days')::bigint
  from public.subscribers
  where unsubscribed = false;
$$;
grant execute on function public.subscribers_stats() to authenticated;
