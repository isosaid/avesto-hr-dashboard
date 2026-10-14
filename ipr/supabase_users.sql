-- Авесто ИПР — учётные записи с паролями.
-- Supabase → SQL Editor → вставить целиком → Run.
-- Создаёт недостающих пользователей и задаёт пароль всем восьми (у существующих пароль заменяется).
-- Можно запускать повторно.

do $$
declare
  r record;
  uid uuid;
begin
  for r in select * from (values
    ('hr@audit.test',         'Hr-HRDr-2OxK-2026',      'Назарова Мадина Рустамовна',              'hr_admin'),
    ('curator01@audit.test',  'Kurator-bH8w-ZFa4-2026', 'Куратор Қурбонов 1',                      'curator'),
    ('curator02@audit.test',  'Kurator2-Dqhu-qBBj-2026', 'Куратор Қурбонов 2', 'curator'),
    ('curator03@audit.test',  'Kurator3-yB2x-WPQw-2026', 'Куратор Қурбонов 3', 'curator'),
    ('curator04@audit.test',  'Kurator4-6VZs-k1OA-2026', 'Куратор Қурбонов 4', 'curator'),
    ('curator05@audit.test',  'Kurator5-AfhP-YuLq-2026', 'Куратор Қурбонов 5', 'curator'),
    ('long@audit.test',       'Rukovod-91g3-0pvM-2026', 'Абдураҳмонзода Ҷамшеджон Ғуломқодирович', 'manager'),
    ('superadmin@audit.test', 'Super-YkfX-b2hI-2026',   'Суперадмин Аудит',                        'superadmin')
  ) as v (email, pw, full_name, role)
  loop
    select id into uid from auth.users where lower(email) = r.email;
    if uid is null then
      uid := gen_random_uuid();
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                              raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                              confirmation_token, recovery_token, email_change_token_new, email_change)
      values ('00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated', r.email,
              extensions.crypt(r.pw, extensions.gen_salt('bf')), now(),
              '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');
      insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), uid, uid::text,
              jsonb_build_object('sub', uid::text, 'email', r.email, 'email_verified', true),
              'email', now(), now(), now());
    else
      update auth.users
         set encrypted_password = extensions.crypt(r.pw, extensions.gen_salt('bf')),
             email_confirmed_at = coalesce(email_confirmed_at, now()),
             updated_at = now()
       where id = uid;
    end if;

    insert into public.ipr_profiles (id, email, full_name, role, must_change_password)
    values (uid, r.email, r.full_name, r.role, false)
    on conflict (id) do update set email = excluded.email, role = excluded.role;
  end loop;
end $$;

-- Проверка: 8 строк, у всех email подтверждён.
select p.email, p.role, p.full_name, u.email_confirmed_at is not null as confirmed
from public.ipr_profiles p join auth.users u on u.id = p.id
order by p.role;
