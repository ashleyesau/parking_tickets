WITH violation_source AS (
  SELECT DISTINCT
    MD5(
      COALESCE(CAST(violation_code AS VARCHAR), '') || 
      COALESCE(violation_county, '') || 
      COALESCE(CAST(violation_precinct AS VARCHAR), '') ||  -- Cast violation_precinct to VARCHAR
      COALESCE(street_name, '')
    ) AS violation_id,
    violation_code,
    violation_description,
    violation_county,
    violation_precinct,
    street_name
  FROM reduced_data
),

-- Clean and enrich violation data
violation_cleaned AS (
  SELECT
    violation_id,

    -- Standardized violation code - handle empty strings properly
    CASE
      WHEN violation_code IS NULL OR violation_code = 0 THEN 'UNKNOWN_CODE'  -- Check for NULL or 0
      ELSE TRIM(UPPER(CAST(violation_code AS VARCHAR)))
    END AS violation_code,

    -- Cleaned violation description
    CASE
      WHEN violation_description IS NULL THEN 'UNSPECIFIED VIOLATION'
      WHEN TRIM(violation_description) = '' THEN 'UNSPECIFIED VIOLATION'
      ELSE INITCAP(REPLACE(TRIM(violation_description), 'Pkng', 'Parking'))
    END AS violation_description,

    -- Standardized county names
    CASE
    WHEN violation_county IS NULL THEN 'UNKNOWN COUNTY'
    WHEN UPPER(TRIM(violation_county)) IN ('MN', 'NY') THEN 'Manhattan'
    WHEN UPPER(TRIM(violation_county)) IN ('Q', 'QN') THEN 'Queens'
    WHEN UPPER(TRIM(violation_county)) IN ('K', 'BK') THEN 'Brooklyn'
    WHEN UPPER(TRIM(violation_county)) IN ('BX') THEN 'Bronx'
    WHEN UPPER(TRIM(violation_county)) IN ('R', 'ST') THEN 'Staten Island'
    ELSE INITCAP(TRIM(violation_county))
    END AS violation_county
,

    -- Cleaned precinct info - ensure empty strings are converted to NULL
    CASE
      WHEN violation_precinct IS NULL OR violation_precinct = 0 THEN NULL  -- Handle NULL or 0 for precinct
      ELSE CAST(violation_precinct AS VARCHAR)
    END AS violation_precinct,

    -- Standardized street names
    CASE
      WHEN street_name IS NULL THEN NULL
      ELSE REPLACE(
             REPLACE(
               INITCAP(TRIM(street_name)),
               ' Ave ', ' Avenue '
             ),
             ' St ', ' Street '
           )
    END AS street_name,

    -- Derived field: violation category - updated to handle unknown codes
    CASE
      WHEN violation_code IS NULL OR violation_code = 0 THEN 'UNCATEGORIZED'  -- Check for NULL or 0
      WHEN SUBSTRING(CAST(violation_code AS VARCHAR), 1, 1) = 'P' THEN 'PARKING VIOLATION'
      WHEN SUBSTRING(CAST(violation_code AS VARCHAR), 1, 1) = 'T' THEN 'TRAFFIC VIOLATION'
      WHEN SUBSTRING(CAST(violation_code AS VARCHAR), 1, 1) BETWEEN '0' AND '9' THEN 'CODE VIOLATION'
      ELSE 'OTHER VIOLATION'
    END AS violation_category,

    -- Derived field: street type
    CASE
      WHEN street_name IS NULL THEN NULL
      WHEN street_name ILIKE '%Avenue%' THEN 'Avenue'
      WHEN street_name ILIKE '%Street%' THEN 'Street'
      WHEN street_name ILIKE '%Boulevard%' THEN 'Boulevard'
      ELSE 'Other'
    END AS street_type,

    -- Derived field: violation specificity
    CASE
      WHEN violation_description IS NULL THEN 'UNKNOWN'
      WHEN violation_description ILIKE '%hydrant%' OR violation_description ILIKE '%crosswalk%' THEN 'SPECIFIC'
      WHEN violation_description ILIKE '%park%' THEN 'GENERAL'
      ELSE 'AMBIGUOUS'
    END AS violation_specificity

  FROM violation_source
)

SELECT * FROM violation_cleaned