{{
  config(
    materialized = 'table'
  )
}}

WITH officer_source AS (
  SELECT DISTINCT
    MD5(COALESCE(issuing_agency, '') || 
        COALESCE(issuer_squad, 'UNASSIGNED') || 
        CAST(COALESCE(issuer_precinct, 0) AS VARCHAR)) AS officer_id,
    issuing_agency,
    issuer_squad,
    issuer_precinct
  FROM reduced_data
),

-- Clean and standardize the data with improved NULL handling
officer_cleaned AS (
  SELECT
    officer_id,
    COALESCE(TRIM(UPPER(issuing_agency)), 'UNKNOWN AGENCY') AS issuing_agency,
    
    -- Strategic NULL handling for issuer_squad with categorization
    CASE
      WHEN issuer_squad IS NULL THEN 'UNASSIGNED'
      WHEN TRIM(issuer_squad) = '' THEN 'UNSPECIFIED'
      ELSE TRIM(UPPER(issuer_squad))
    END AS issuer_squad,
    
    -- Convert the precinct from bigint to an integer representation
    COALESCE(issuer_precinct, 0) AS issuer_precinct
  FROM officer_source
)

SELECT * FROM officer_cleaned