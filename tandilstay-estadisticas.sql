-- ============================================================
-- TandilStay · Estadísticas de visitas
-- Pegar en Supabase → SQL Editor → Run. Seguro de re-ejecutar.
-- (Necesita que ya hayas corrido antes el SQL de seguridad, porque usa is_admin().)
-- ============================================================

-- Tabla de visitas: una fila por publicación y por día
create table if not exists public.listing_views (
  rubro text not null,           -- 'hospedaje' | 'gastronomia' | 'actividad'
  slug  text not null,
  day   date not null default current_date,
  count integer not null default 0,
  primary key (rubro, slug, day)
);
alter table public.listing_views enable row level security;
-- No creamos políticas: a esta tabla solo se entra por las funciones de abajo.

-- Sumar una visita. La llaman las fichas públicas, incluso sin estar logueado.
create or replace function public.bump_view(p_rubro text, p_slug text)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.listing_views (rubro, slug, day, count)
  values (p_rubro, p_slug, current_date, 1)
  on conflict (rubro, slug, day) do update set count = listing_views.count + 1;
end $$;
grant execute on function public.bump_view(text, text) to anon, authenticated;

-- Ver las visitas de las publicaciones propias (o de todas, si sos admin).
create or replace function public.my_views()
returns table(rubro text, slug text, total bigint, last30 bigint)
language sql security definer set search_path = public as $$
  with mine as (
    select 'hospedaje'::text rubro, slug from public.cabins
      where public.is_admin() or operator = (select operator from public.profiles where id = auth.uid())
    union all
    select 'gastronomia', slug from public.restaurants
      where public.is_admin() or operator = (select operator from public.profiles where id = auth.uid())
    union all
    select 'actividad', slug from public.activities
      where public.is_admin() or operator = (select operator from public.profiles where id = auth.uid())
  )
  select m.rubro, m.slug,
         coalesce(sum(v.count), 0)::bigint as total,
         coalesce(sum(v.count) filter (where v.day >= current_date - 29), 0)::bigint as last30
  from mine m
  left join public.listing_views v on v.rubro = m.rubro and v.slug = m.slug
  group by m.rubro, m.slug;
$$;
grant execute on function public.my_views() to authenticated;
