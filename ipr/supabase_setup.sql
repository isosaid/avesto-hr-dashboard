-- Авесто ИПР — вход по паролю через Supabase.
-- Запускать в Supabase → SQL Editor → New query → Run.
-- Порядок: 1) создать пользователей в Authentication → Users → Add user (Auto Confirm User);
--          2) выполнить этот скрипт — он создаст таблицу ролей и привяжет пользователей по email.
-- Скрипт можно запускать повторно: он ничего не дублирует.

-- 1. Профили: роль и ФИО для каждой учётной записи Supabase Auth.
create table if not exists public.ipr_profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  full_name text not null,
  role text not null check (role in ('superadmin', 'hr_admin', 'curator', 'manager')),
  must_change_password boolean not null default false,
  created_at timestamptz not null default now()
);

-- 2. Доступ: пользователь видит только свою строку и может лишь снять флаг «сменить пароль».
alter table public.ipr_profiles enable row level security;
revoke all on public.ipr_profiles from anon, authenticated;
grant select on public.ipr_profiles to authenticated;
grant update (must_change_password) on public.ipr_profiles to authenticated;

drop policy if exists "ipr: читать свой профиль" on public.ipr_profiles;
create policy "ipr: читать свой профиль" on public.ipr_profiles
  for select to authenticated
  using (id = (select auth.uid()));

drop policy if exists "ipr: снять флаг смены пароля" on public.ipr_profiles;
create policy "ipr: снять флаг смены пароля" on public.ipr_profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()) and must_change_password = false);

-- 3. Роли для учётных записей (те же, что на скриншотах продукта).
--    Сначала создайте этих пользователей в Authentication → Users.
--    must_change_password = true — при первом входе система попросит сменить пароль.
insert into public.ipr_profiles (id, email, full_name, role, must_change_password)
select u.id, v.email, v.full_name, v.role, v.must_change
from (values
  ('superadmin@audit.test', 'Суперадмин Аудит',                          'superadmin', false),
  ('hr@audit.test',         'Назарова Мадина Рустамовна',                'hr_admin',   false),
  ('curator01@audit.test',  'Куратор Қурбонов 1',                        'curator',    false),
  ('long@audit.test',       'Абдураҳмонзода Ҷамшеджон Ғуломқодирович',   'manager',    false)
) as v (email, full_name, role, must_change)
join auth.users u on lower(u.email) = v.email
on conflict (id) do update
  set email = excluded.email, full_name = excluded.full_name, role = excluded.role;

-- Проверка: должно вернуть 4 строки.
select email, role, full_name, must_change_password from public.ipr_profiles order by role;
