-- ============================================================
-- Visitando Tandil · Contraseñas para probar los tres paneles
-- Pegar en Supabase → SQL Editor → Run.
--
-- Cambiá 'TandilPrueba2026!' por la que quieras usar.
-- Podés poner la misma para los tres, así probás rápido.
-- ============================================================

update auth.users
set encrypted_password = crypt('TandilPrueba2026!', gen_salt('bf'))
where email in (
  'hospedatentandil@gmail.com',   -- panel.html        (hospedajes)
  'testgastronomia@gmail.com',    -- gastro-panel.html (gastronomía)
  'testactividad@gmail.com'       -- act-panel.html    (actividades)
);

-- Para ver que quedaron los tres:
select email, role from public.profiles
where email in (
  'hospedatentandil@gmail.com',
  'testgastronomia@gmail.com',
  'testactividad@gmail.com'
);

-- Si alguno no aparece en profiles, avisá: significa que el perfil
-- quedó a medias y hay que crearlo aparte.
