{{
  config(
    materialized = 'table'
  )
}}

WITH date_spine AS (
  -- Create a date spine from the minimum to maximum date in your data
  -- This ensures your dimension covers all dates in your fact table
  SELECT DISTINCT
    TO_DATE(issue_date, 'MM/DD/YYYY') AS date_id
  FROM {{ source('parking_tickets_db', 'reduced_data') }}
  WHERE issue_date IS NOT NULL
),

date_dimension AS (
  SELECT
    -- Primary Key
    date_id,
    
    -- Date Components
    EXTRACT(YEAR FROM date_id) AS year,
    EXTRACT(MONTH FROM date_id) AS month_num,
    EXTRACT(DAY FROM date_id) AS day_num,
    EXTRACT(DAYOFWEEK FROM date_id) AS day_of_week_num,
    EXTRACT(QUARTER FROM date_id) AS quarter_num,
    
    -- Date Descriptions
    TO_CHAR(date_id, 'YYYY-MM-DD') AS date_string,
    TO_CHAR(date_id, 'Month') AS month_name,
    TO_CHAR(date_id, 'Mon') AS month_short_name,
    TO_CHAR(date_id, 'Day') AS day_name,
    TO_CHAR(date_id, 'DY') AS day_short_name,
    
    -- Fiscal Periods (adjust fiscal_year_start as needed for your organization)
    CASE
      WHEN EXTRACT(MONTH FROM date_id) >= 7 THEN EXTRACT(YEAR FROM date_id) + 1
      ELSE EXTRACT(YEAR FROM date_id)
    END AS fiscal_year, -- Assuming fiscal year starts in July
    
    -- Special Day Flags
    CASE WHEN EXTRACT(MONTH FROM date_id) = 1 AND EXTRACT(DAY FROM date_id) = 1 THEN TRUE ELSE FALSE END AS is_new_years,
    CASE WHEN TO_CHAR(date_id, 'MM-DD') IN ('12-25', '12-24') THEN TRUE ELSE FALSE END AS is_christmas,
    CASE WHEN EXTRACT(DAYOFWEEK FROM date_id) IN (0, 6) THEN TRUE ELSE FALSE END AS is_weekend,
    
    -- Time Intelligence Fields
    DATE_TRUNC('MONTH', date_id) AS first_day_of_month,
    LAST_DAY(date_id) AS last_day_of_month,
    DATE_TRUNC('YEAR', date_id) AS first_day_of_year,
    
    -- Current Date Flags
    CASE WHEN TO_CHAR(date_id, 'YYYY-MM-DD') = TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') THEN TRUE ELSE FALSE END AS is_current_day,
    CASE WHEN EXTRACT(YEAR FROM date_id) = EXTRACT(YEAR FROM CURRENT_DATE) THEN TRUE ELSE FALSE END AS is_current_year,
    CASE 
      WHEN EXTRACT(YEAR FROM date_id) = EXTRACT(YEAR FROM CURRENT_DATE) 
      AND EXTRACT(MONTH FROM date_id) = EXTRACT(MONTH FROM CURRENT_DATE) 
      THEN TRUE ELSE FALSE 
    END AS is_current_month
  FROM date_spine
)

SELECT * FROM date_dimension
ORDER BY date_id