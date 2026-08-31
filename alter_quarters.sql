-- Разрешить 4 квартала + годовой отчёт
ALTER TABLE courses DROP CONSTRAINT IF EXISTS courses_quarter_check;
ALTER TABLE courses ADD CONSTRAINT courses_quarter_check
  CHECK (quarter IN ('q1','q2','q3','q4'));

-- month_index теперь 1..12
ALTER TABLE courses ADD COLUMN IF NOT EXISTS month_index INTEGER;

-- KPI участников по всем периодам
INSERT INTO report_meta(period, participants) VALUES
  ('q3', 0), ('q4', 0), ('year', 582)
ON CONFLICT (period) DO NOTHING;
