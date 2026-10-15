-- ============================================================
-- Visitando Tandil · Dominio propio de cada cliente
-- Pegar en Supabase → SQL Editor → Run. Seguro de re-ejecutar.
-- ============================================================

-- 1) La columna. Se guarda limpio: "hospedatentandil.com.ar" (sin https://, sin www, sin barra)
alter table public.profiles add column if not exists dominio text;

create index if not exists profiles_dominio_idx
  on public.profiles (lower(dominio));

-- Normaliza lo que venga: "https://www.Hospeda.com.ar/algo" → "hospeda.com.ar"
create or replace function public.limpiar_dominio(d text)
returns text
language sql
immutable
as $$
  select nullif(
    regexp_replace(
      regexp_replace(
        regexp_replace(lower(trim(coalesce(d, ''))), '^[a-z]+://', ''),
      '^www\.', ''),
    '[/?#].*$', ''),
  '');
$$;

-- 2) Dominio → operador. La usan las páginas públicas sin estar logueadas.
--    security definer: lee profiles salteando RLS, pero solo devuelve el nombre del operador.
create or replace function public.operador_por_dominio(p_dominio text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select trim(p.operator)
  from public.profiles p
  where public.limpiar_dominio(p.dominio) = public.limpiar_dominio(p_dominio)
    and coalesce(trim(p.operator), '') <> ''
    and coalesce(p.role, '') <> 'admin'
  order by p.created_at
  limit 1;
$$;

-- 3) Lista operador → dominio, para que la sábana de visitandotandil.com
--    mande cada hospedaje a la web propia de su dueño.
create or replace function public.dominios_publicos()
returns table (operator text, dominio text)
language sql
stable
security definer
set search_path = public
as $$
  select distinct on (lower(trim(p.operator)))
         trim(p.operator), public.limpiar_dominio(p.dominio)
  from public.profiles p
  where public.limpiar_dominio(p.dominio) is not null
    and coalesce(trim(p.operator), '') <> ''
    and coalesce(p.role, '') <> 'admin'
  order by lower(trim(p.operator)), p.created_at;
$$;

revoke all on function public.operador_por_dominio(text) from public;
revoke all on function public.dominios_publicos() from public;
grant execute on function public.operador_por_dominio(text) to anon, authenticated;
grant execute on function public.dominios_publicos() to anon, authenticated;
