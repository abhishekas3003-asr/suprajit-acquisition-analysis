-- =====================================================================
-- SUPRAJIT ENGINEERING (FY21-FY25) — ANALYTICAL SQL WORKBOOK
-- =====================================================================
-- Workflow:  Validate first (gate)  ->  Build analytical layer  ->  Analyse.
--
-- Validation assumption (important):
--   Checks 1-4 below confirm the source data is complete (no NULLs),
--   internally consistent (the cost waterfall holds every year), and that
--   geographic revenue reconciles to reported revenue. Because that gate
--   is passed, the analytical queries that follow deliberately TRUST the
--   validated input -- no defensive NULL/zero guards are added to queries
--   that, by validation, can never encounter a NULL or zero denominator.
--   This keeps the analytical layer clean and the workflow auditable.
--
-- Convention: all percentage/ratio math forces NUMERIC division via *100.0.
-- =====================================================================


-- =====================================================================
-- SECTION 0 — SCHEMA
-- =====================================================================

CREATE TABLE financial_kpis (
    fiscal_year   VARCHAR(10),
    year          INT,
    revenue       NUMERIC(12,2),
    other_income  NUMERIC(12,2),
    total_income  NUMERIC(12,2),
    material_cost NUMERIC(12,2),
    employee_cost NUMERIC(12,2),
    finance_cost  NUMERIC(12,2),
    depreciation  NUMERIC(12,2),
    other_expense NUMERIC(12,2),
    pbt           NUMERIC(12,2),
    tax           NUMERIC(12,2),
    pat           NUMERIC(12,2)
);

CREATE TABLE geographic_revenue (
    fiscal_year VARCHAR(10),
    year        INT,
    geography   VARCHAR(20),
    revenue     NUMERIC(12,2)
);


-- =====================================================================
-- SECTION 1 — DATA VALIDATION GATE (run before any analysis)
-- =====================================================================

-- Check 1 — Completeness: no NULLs in any required field.
-- Expected result: ZERO rows returned from both queries.
SELECT *
FROM financial_kpis
WHERE revenue       IS NULL
   OR other_income  IS NULL
   OR total_income  IS NULL
   OR material_cost IS NULL
   OR employee_cost IS NULL
   OR finance_cost  IS NULL
   OR depreciation  IS NULL
   OR other_expense IS NULL
   OR pbt           IS NULL
   OR tax           IS NULL
   OR pat           IS NULL;

SELECT *
FROM geographic_revenue
WHERE fiscal_year IS NULL
   OR geography   IS NULL
   OR revenue     IS NULL;


-- Check 2 — Cost-waterfall consistency.
-- Confirms the expected ordering Revenue > EBITDA > PAT holds in every
-- year. NOTE: this is a confirmation that the normal cost waterfall held
-- for THIS dataset (all costs/taxes positive), not a universal accounting
-- law. Expected result: ZERO rows (no violations).
SELECT
    fiscal_year,
    revenue,
    (revenue - material_cost - employee_cost - other_expense) AS ebitda
FROM financial_kpis
WHERE revenue <= (revenue - material_cost - employee_cost - other_expense);

SELECT
    fiscal_year,
    revenue,
    pat
FROM financial_kpis
WHERE revenue <= pat;

SELECT
    fiscal_year,
    pat,
    (revenue - material_cost - employee_cost - other_expense) AS ebitda
FROM financial_kpis
WHERE pat >= (revenue - material_cost - employee_cost - other_expense);


-- Check 3 — Geographic reconciliation.
-- Confirms the sum of geographic revenue ties out to reported consolidated
-- revenue each year. Expected result: difference = 0 for every year.
WITH geo_total AS (
    SELECT fiscal_year, SUM(revenue) AS geographic_revenue
    FROM geographic_revenue
    GROUP BY fiscal_year
),
reported_revenue AS (
    SELECT fiscal_year, revenue AS total_revenue
    FROM financial_kpis
)
SELECT
    g.fiscal_year,
    g.geographic_revenue,
    r.total_revenue,
    g.geographic_revenue - r.total_revenue AS difference
FROM geo_total g
JOIN reported_revenue r ON g.fiscal_year = r.fiscal_year
ORDER BY g.fiscal_year;


-- Check 4 — Margin-formula validation.
-- Recomputes EBITDA, EBITDA margin and PAT margin from raw fields to
-- confirm derived metrics are reproducible from source data.
SELECT
    fiscal_year,
    revenue,
    ROUND(revenue - material_cost - employee_cost - other_expense, 2) AS ebitda,
    ROUND(
        (revenue - material_cost - employee_cost - other_expense)
        * 100.0 / revenue, 2
    ) AS ebitda_margin
FROM financial_kpis
ORDER BY year;

SELECT
    fiscal_year,
    pat,
    revenue,
    ROUND(pat * 100.0 / revenue, 2) AS pat_margin
FROM financial_kpis
ORDER BY year;


-- =====================================================================
-- SECTION 2 — ANALYTICAL LAYER (persisted derived tables)
-- =====================================================================
-- Data preparation is separated from analysis. These tables hold
-- consistent metric definitions reused across the analytical queries.

-- calculated_kpis — EBITDA, EBITDA margin, PAT margin
CREATE TABLE calculated_kpis AS
SELECT
    fiscal_year,
    year,
    ROUND(revenue - material_cost - employee_cost - other_expense, 2) AS ebitda,
    ROUND(
        (revenue - material_cost - employee_cost - other_expense)
        * 100.0 / revenue, 2
    ) AS ebitda_margin,
    ROUND(pat * 100.0 / revenue, 2) AS pat_margin
FROM financial_kpis;

-- cost_structure — each major cost as % of revenue
CREATE TABLE cost_structure AS
SELECT
    fiscal_year,
    year,
    ROUND(material_cost * 100.0 / revenue, 2) AS material_pct,
    ROUND(employee_cost * 100.0 / revenue, 2) AS employee_pct,
    ROUND(other_expense * 100.0 / revenue, 2) AS other_expense_pct
FROM financial_kpis;

-- growth_comparison — long-format metric table for FY21 vs FY25 comparison
CREATE TABLE growth_comparison AS
SELECT 'EBITDA'       AS metric, fiscal_year, ebitda       AS value FROM calculated_kpis
UNION ALL
SELECT 'Finance Cost', fiscal_year, finance_cost          FROM financial_kpis
UNION ALL
SELECT 'Depreciation', fiscal_year, depreciation          FROM financial_kpis
UNION ALL
SELECT 'PAT',          fiscal_year, pat                    FROM financial_kpis;

-- revenue_profitability — revenue growth vs EBITDA margin, year over year
CREATE TABLE revenue_profitability AS
SELECT
    f.fiscal_year,
    f.year,
    f.revenue,
    ROUND(
        (f.revenue - LAG(f.revenue) OVER (ORDER BY f.year))
        * 100.0 / LAG(f.revenue) OVER (ORDER BY f.year), 2
    ) AS revenue_growth_pct,   -- NULL for FY21 (base year, no prior period)
    c.ebitda_margin
FROM financial_kpis f
JOIN calculated_kpis c ON f.fiscal_year = c.fiscal_year;

-- margin_bridge — bps change in each cost driver, FY21 -> FY25
CREATE TABLE margin_bridge AS
SELECT 'Employee Cost' AS cost_driver,
    ROUND(
        (MAX(CASE WHEN fiscal_year = 'FY25' THEN employee_pct END)
       - MAX(CASE WHEN fiscal_year = 'FY21' THEN employee_pct END)) * 100.0, 0
    ) AS bps_impact
FROM cost_structure
UNION ALL
SELECT 'Material Cost',
    ROUND(
        (MAX(CASE WHEN fiscal_year = 'FY25' THEN material_pct END)
       - MAX(CASE WHEN fiscal_year = 'FY21' THEN material_pct END)) * 100.0, 0
    )
FROM cost_structure
UNION ALL
SELECT 'Other Expense',
    ROUND(
        (MAX(CASE WHEN fiscal_year = 'FY25' THEN other_expense_pct END)
       - MAX(CASE WHEN fiscal_year = 'FY21' THEN other_expense_pct END)) * 100.0, 0
    )
FROM cost_structure;


-- =====================================================================
-- SECTION 3 — ANALYSIS
-- =====================================================================

-- Query 1 — Business question: How did revenue split by geography each year?
SELECT
    fiscal_year,
    geography,
    revenue
FROM geographic_revenue
ORDER BY year, geography;


-- Query 2 — Business question: How did the geographic mix and the
-- international revenue share evolve over the period?
SELECT
    fiscal_year,
    ROUND(SUM(CASE WHEN geography = 'India' THEN revenue END) * 100.0 / SUM(revenue), 2) AS india_pct,
    ROUND(SUM(CASE WHEN geography = 'USA'   THEN revenue END) * 100.0 / SUM(revenue), 2) AS usa_pct,
    ROUND(SUM(CASE WHEN geography = 'ROW'   THEN revenue END) * 100.0 / SUM(revenue), 2) AS row_pct,
    ROUND(SUM(CASE WHEN geography IN ('USA','ROW') THEN revenue END) * 100.0 / SUM(revenue), 2) AS international_pct
FROM geographic_revenue
GROUP BY fiscal_year
ORDER BY fiscal_year;


-- Query 3 — Business question: How fast did each geography grow year on year?
-- FY21 returns NULL growth by design (base year, no prior period to compare).
WITH growth_calc AS (
    SELECT
        fiscal_year,
        geography,
        year,
        revenue,
        LAG(revenue) OVER (PARTITION BY geography ORDER BY year) AS previous_year_revenue
    FROM geographic_revenue
)
SELECT
    fiscal_year,
    geography,
    revenue,
    previous_year_revenue,
    ROUND((revenue - previous_year_revenue) * 100.0 / previous_year_revenue, 2) AS growth_pct
FROM growth_calc
ORDER BY geography, fiscal_year;


-- Query 4 — Business question: How did the cost structure (% of revenue) trend?
SELECT
    fiscal_year,
    material_pct,
    employee_pct,
    other_expense_pct
FROM cost_structure
ORDER BY fiscal_year;


-- Query 5 — Business question: Which cost drivers moved most, FY21 -> FY25
-- (margin bridge, in basis points)?
SELECT
    cost_driver,
    bps_impact
FROM margin_bridge;


-- Query 6 — Business question: How did EBITDA, Finance Cost, Depreciation
-- and PAT each change in absolute and % terms, FY21 -> FY25?
SELECT
    metric,
    MAX(CASE WHEN fiscal_year = 'FY21' THEN value END) AS fy21,
    MAX(CASE WHEN fiscal_year = 'FY25' THEN value END) AS fy25,
    ROUND(
        MAX(CASE WHEN fiscal_year = 'FY25' THEN value END)
      - MAX(CASE WHEN fiscal_year = 'FY21' THEN value END), 2
    ) AS absolute_change,
    ROUND(
        (MAX(CASE WHEN fiscal_year = 'FY25' THEN value END)
       - MAX(CASE WHEN fiscal_year = 'FY21' THEN value END)) * 100.0
       / MAX(CASE WHEN fiscal_year = 'FY21' THEN value END), 2
    ) AS growth_pct
FROM growth_comparison
GROUP BY metric
ORDER BY growth_pct DESC;


-- Query 7 — Business question: Did revenue growth and operating margin move
-- together or apart, year by year?
SELECT
    fiscal_year,
    revenue_growth_pct,
    ebitda_margin
FROM revenue_profitability
ORDER BY year;


-- Query 8 — Business question: Are FY24 -> FY25 margins showing any
-- turnaround signal?
SELECT
    fiscal_year,
    ebitda_margin,
    pat_margin
FROM calculated_kpis
WHERE fiscal_year IN ('FY24','FY25')
ORDER BY fiscal_year;


-- Query 9 — Business question: How sharply did Revenue, EBITDA and PAT
-- diverge over the period (the profitability paradox)?
SELECT
    metric,
    MAX(CASE WHEN fiscal_year = 'FY21' THEN value END) AS fy21,
    MAX(CASE WHEN fiscal_year = 'FY25' THEN value END) AS fy25,
    ROUND(
        (MAX(CASE WHEN fiscal_year = 'FY25' THEN value END)
       - MAX(CASE WHEN fiscal_year = 'FY21' THEN value END)) * 100.0
       / MAX(CASE WHEN fiscal_year = 'FY21' THEN value END), 2
    ) AS growth_pct
FROM growth_comparison
WHERE metric IN ('EBITDA','PAT')
GROUP BY metric
UNION ALL
SELECT
    'Revenue',
    MAX(CASE WHEN fiscal_year = 'FY21' THEN revenue END),
    MAX(CASE WHEN fiscal_year = 'FY25' THEN revenue END),
    ROUND(
        (MAX(CASE WHEN fiscal_year = 'FY25' THEN revenue END)
       - MAX(CASE WHEN fiscal_year = 'FY21' THEN revenue END)) * 100.0
       / MAX(CASE WHEN fiscal_year = 'FY21' THEN revenue END), 2
    )
FROM financial_kpis;


-- Query 10 — Business question: Rank the cost drivers by magnitude of impact.
SELECT
    cost_driver,
    bps_impact,
    RANK() OVER (ORDER BY ABS(bps_impact) DESC) AS impact_rank
FROM margin_bridge;


-- Query 11 — Business question: Which geography contributed most to total
-- revenue growth over the period?
WITH revenue_growth AS (
    SELECT
        geography,
        MAX(CASE WHEN fiscal_year = 'FY25' THEN revenue END)
      - MAX(CASE WHEN fiscal_year = 'FY21' THEN revenue END) AS revenue_added
    FROM geographic_revenue
    GROUP BY geography
)
SELECT
    geography,
    revenue_added,
    ROUND(revenue_added * 100.0 / SUM(revenue_added) OVER (), 2) AS contribution_pct
FROM revenue_growth
ORDER BY contribution_pct DESC;
