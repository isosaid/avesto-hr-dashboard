-- ============================================================
-- Avesto HR Dashboard — Supabase Schema
-- Запустить в: Supabase → SQL Editor → New query → Run
-- ============================================================

-- 1. Аккаунты (через Supabase Auth — встроено автоматически)
--    Дополнительный профиль пользователя
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT UNIQUE NOT NULL,
  role        TEXT DEFAULT 'viewer', -- viewer | editor | admin
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Справочник компаний
CREATE TABLE IF NOT EXISTS companies (
  id           SERIAL PRIMARY KEY,
  name         TEXT UNIQUE NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Курсы (факт-таблица)
CREATE TABLE IF NOT EXISTS courses (
  id           SERIAL PRIMARY KEY,
  quarter      TEXT NOT NULL CHECK (quarter IN ('q1','q2')),
  company_id   INTEGER REFERENCES companies(id),
  course_name  TEXT NOT NULL,
  format       TEXT CHECK (format IN ('Офлайн','Онлайн')),
  participants INTEGER DEFAULT 0,
  duration     TEXT,
  cost_raw     TEXT DEFAULT '—',
  cost_num     NUMERIC,
  category     TEXT,
  created_by   UUID REFERENCES auth.users(id),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 4. KPI участников (авторитетные числа из отчёта)
CREATE TABLE IF NOT EXISTS report_meta (
  period       TEXT PRIMARY KEY,  -- q1 | q2 | h1
  participants INTEGER NOT NULL
);
INSERT INTO report_meta(period, participants) VALUES
  ('q1', 288), ('q2', 294), ('h1', 582)
ON CONFLICT (period) DO NOTHING;

-- 5. План потребности
CREATE TABLE IF NOT EXISTS needs_plan (
  id           SERIAL PRIMARY KEY,
  title        TEXT NOT NULL,
  completed    BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- RLS (Row Level Security) — кто что видит
-- ============================================================
ALTER TABLE profiles    ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies   ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses     ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_meta ENABLE ROW LEVEL SECURITY;
ALTER TABLE needs_plan  ENABLE ROW LEVEL SECURITY;

-- Все авторизованные видят данные
CREATE POLICY "auth read profiles"    ON profiles    FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth read companies"   ON companies   FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth read courses"     ON courses     FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth read meta"        ON report_meta FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "auth read needs"       ON needs_plan  FOR SELECT USING (auth.role() = 'authenticated');

-- Все авторизованные могут добавлять/изменять/удалять курсы и компании
CREATE POLICY "auth write companies"  ON companies   FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth write courses"    ON courses     FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "auth delete courses"   ON courses     FOR DELETE USING (auth.role() = 'authenticated');
CREATE POLICY "auth update courses"   ON courses     FOR UPDATE USING (auth.role() = 'authenticated');

-- Пользователь видит/меняет только свой профиль
CREATE POLICY "own profile"           ON profiles    FOR ALL USING (auth.uid() = id);

-- ============================================================
-- Данные: компании из отчёта
-- ============================================================
INSERT INTO companies(name) VALUES
  ('Азот'),('Анор'),('ДС Банк / DC Bank'),('Зет Мобайл'),
  ('Jura'),('Мармари'),('Нетс'),('Олуча'),
  ('Пайванд'),('Сиёма Молл'),('Акиа Авесто'),('Гулистони Душанбе')
ON CONFLICT (name) DO NOTHING;
