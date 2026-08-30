PRAGMA foreign_keys=ON;

CREATE TABLE dim_company(
  company_id   INTEGER PRIMARY KEY,
  company_name TEXT NOT NULL UNIQUE
);
CREATE TABLE fact_course(
  course_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  quarter      TEXT NOT NULL,                 -- q1 | q2
  period       TEXT NOT NULL,
  company_id   INTEGER NOT NULL REFERENCES dim_company(company_id),
  course_name  TEXT NOT NULL,
  format       TEXT,                          -- Офлайн | Онлайн
  participants INTEGER,
  duration     TEXT,
  cost_raw     TEXT,                           -- как в отчёте: "6 400 c" / "Бесплатно" / "—"
  cost_num     REAL,                           -- очищенное число (сомони), NULL если не задано
  category     TEXT
);
CREATE INDEX ix_course_company ON fact_course(company_id);
CREATE INDEX ix_course_quarter ON fact_course(quarter);
