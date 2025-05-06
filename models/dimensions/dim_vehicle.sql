{{
  config(
    materialized = 'table'
  )
}}

WITH vehicle_source AS (
  SELECT DISTINCT
    MD5(
      COALESCE(plate_id, '') || 
      COALESCE(plate_type, 'UNKNOWN') || 
      COALESCE(vehicle_body_type, '') || 
      COALESCE(vehicle_make, '') || 
      COALESCE(CAST(vehicle_year AS VARCHAR), '0') || 
      COALESCE(registration_state, '')
    ) AS vehicle_id,
    plate_id,
    plate_type,
    vehicle_body_type,
    vehicle_make,
    vehicle_year,
    registration_state
  FROM reduced_data
),

vehicle_cleaned AS (
  SELECT
    vehicle_id,

    CASE
      WHEN plate_id IS NULL THEN NULL
      WHEN TRIM(plate_id) = '' THEN NULL
      ELSE TRIM(UPPER(plate_id))
    END AS plate_id,

    CASE
      WHEN plate_type IS NULL THEN 'UNKNOWN'
      WHEN TRIM(UPPER(plate_type)) IN ('PAS', 'PASSENGER', 'PERSONAL') THEN 'PASSENGER'
      WHEN TRIM(UPPER(plate_type)) IN ('COM', 'COMMERCIAL') THEN 'COMMERCIAL'
      WHEN TRIM(plate_type) = '' THEN 'STANDARD'
      ELSE TRIM(UPPER(plate_type))
    END AS plate_type,

    CASE
      WHEN vehicle_body_type IS NULL THEN 'UNKNOWN'
      WHEN TRIM(UPPER(vehicle_body_type)) = 'SUV' THEN 'SPORT UTILITY VEHICLE'
      WHEN TRIM(UPPER(vehicle_body_type)) = 'PK' THEN 'PICKUP TRUCK'
      ELSE TRIM(UPPER(vehicle_body_type))
    END AS vehicle_body_type,

    CASE
      WHEN vehicle_make IS NULL THEN 'UNKNOWN MAKE'
      WHEN TRIM(UPPER(vehicle_make)) = 'TOY' THEN 'TOYOTA'
      WHEN TRIM(UPPER(vehicle_make)) = 'VW' THEN 'VOLKSWAGEN'
      ELSE TRIM(UPPER(vehicle_make))
    END AS vehicle_make,

    CASE
      WHEN vehicle_year IS NULL THEN NULL
      WHEN vehicle_year < 1900 THEN NULL
      WHEN vehicle_year > EXTRACT(YEAR FROM CURRENT_DATE) + 1 THEN NULL
      ELSE vehicle_year
    END AS vehicle_year,

    CASE
      WHEN registration_state IS NULL THEN NULL
      WHEN LENGTH(TRIM(registration_state)) = 2 THEN UPPER(TRIM(registration_state))
      WHEN TRIM(UPPER(registration_state)) = 'NEW YORK' THEN 'NY'
      WHEN TRIM(UPPER(registration_state)) = 'CALIFORNIA' THEN 'CA'
      ELSE UPPER(SUBSTRING(TRIM(registration_state), 1, 2))
    END AS registration_state,

    CASE
      WHEN vehicle_year IS NULL THEN 'UNKNOWN AGE'
      WHEN EXTRACT(YEAR FROM CURRENT_DATE) - vehicle_year <= 2 THEN 'NEW (0-2 YEARS)'
      WHEN EXTRACT(YEAR FROM CURRENT_DATE) - vehicle_year <= 5 THEN 'USED (3-5 YEARS)'
      WHEN EXTRACT(YEAR FROM CURRENT_DATE) - vehicle_year <= 10 THEN 'OLDER (6-10 YEARS)'
      ELSE 'VINTAGE (10+ YEARS)'
    END AS vehicle_age_category

  FROM vehicle_source
)

SELECT * FROM vehicle_cleaned
