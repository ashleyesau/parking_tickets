
# Data Checks on Raw Data in Athena

---

### Step One: Created New Table with Only Relevant Columns (Renamed Variables to Include Underscores)

```sql
CREATE TABLE reduced_data
WITH (
  format = 'PARQUET',
  external_location = 's3://parkingticketdata/processed_data/'
)
AS
SELECT 
  "summons number" AS summons_number,
  "issue date" AS issue_date,
  "plate id" AS plate_id,
  "plate type" AS plate_type,
  "violation code" AS violation_code,
  "violation description" AS violation_description,
  "violation county" AS violation_county,
  "violation precinct" AS violation_precinct,
  "street name" AS street_name,
  "registration state" AS registration_state,
  "vehicle body type" AS vehicle_body_type,
  "vehicle make" AS vehicle_make,
  "vehicle year" AS vehicle_year,
  "issuing agency" AS issuing_agency,
  "issuer squad" AS issuer_squad,
  "issuer precinct" AS issuer_precinct
FROM raw_data;
```
### Step 2: Checked counts of rows and columns of both tables to ensure a match

```sql
--- Count comparison
SELECT 
  (SELECT COUNT(*) FROM raw_data) AS raw_count,
  (SELECT COUNT(*) FROM reduced_data) AS reduced_count,
  (SELECT COUNT(*) FROM raw_data) - (SELECT COUNT(*) FROM reduced_data) AS difference,
  CASE 
    WHEN (SELECT COUNT(*) FROM raw_data) = (SELECT COUNT(*) FROM reduced_data) 
    THEN 'MATCH' 
    ELSE 'MISMATCH' 
  END AS validation_status
  ```

[![Screenshot-2025-04-28-at-18-15-29.png](https://i.postimg.cc/prkkSFdG/Screenshot-2025-04-28-at-18-15-29.png)](https://postimg.cc/SY2W2jCC)
---
```sql
SELECT 
  column_name,
  raw_count,
  reduced_count,
  raw_count - reduced_count AS difference
FROM (
  SELECT 
    'summons_number' AS column_name,
    (SELECT COUNT("summons number") FROM raw_data) AS raw_count,
    (SELECT COUNT(summons_number) FROM reduced_data) AS reduced_count
  
  UNION ALL
  
  SELECT 
    'issue_date',
    (SELECT COUNT("issue date") FROM raw_data),
    (SELECT COUNT(issue_date) FROM reduced_data)
  
  UNION ALL
  
  SELECT 
    'violation_code',
    (SELECT COUNT("violation code") FROM raw_data),
    (SELECT COUNT(violation_code) FROM reduced_data)
)
```


[![Screenshot-2025-04-28-at-18-15-42.png](https://i.postimg.cc/j2RZvXRn/Screenshot-2025-04-28-at-18-15-42.png)](https://postimg.cc/7GQ3ZSGq)
---
### Count the Number of Columns in raw_data vs reduced_data

```sql
WITH 
raw_columns AS (
  SELECT COUNT(*) AS raw_column_count 
  FROM information_schema.columns 
  WHERE table_name = 'raw_data'
),
reduced_columns AS (
  SELECT COUNT(*) AS reduced_column_count 
  FROM information_schema.columns 
  WHERE table_name = 'reduced_data'
)
SELECT 
  r.raw_column_count,
  rd.reduced_column_count,
  r.raw_column_count - rd.reduced_column_count AS columns_removed
FROM raw_columns r
CROSS JOIN reduced_columns rd
```
[![Screenshot-2025-04-28-at-18-22-08.png](https://i.postimg.cc/1tBpRZZ4/Screenshot-2025-04-28-at-18-22-08.png)](https://postimg.cc/qhttQSqd)

---
### Identified which columns have NULL values
```sql
SELECT
  COUNT(*) - COUNT(summons_number) AS null_summons_number,
  COUNT(*) - COUNT(issue_date) AS null_issue_date,
  COUNT(*) - COUNT(plate_id) AS null_plate_id,
  COUNT(*) - COUNT(plate_type) AS null_plate_type,
  COUNT(*) - COUNT(violation_code) AS null_violation_code,
  COUNT(*) - COUNT(violation_description) AS null_violation_description,
  COUNT(*) - COUNT(violation_county) AS null_violation_county,
  COUNT(*) - COUNT(violation_precinct) AS null_violation_precinct,
  COUNT(*) - COUNT(street_name) AS null_street_name,
  COUNT(*) - COUNT(registration_state) AS null_registration_state,
  COUNT(*) - COUNT(vehicle_body_type) AS null_vehicle_body_type,
  COUNT(*) - COUNT(vehicle_make) AS null_vehicle_make,
  COUNT(*) - COUNT(vehicle_year) AS null_vehicle_year,
  COUNT(*) - COUNT(issuing_agency) AS null_issuing_agency,
  COUNT(*) - COUNT(issuer_squad) AS null_issuer_squad,
  COUNT(*) - COUNT(issuer_precinct) AS null_issuer_precinct,
  COUNT(*) AS total_records
FROM reduced_data
```
- violation_code: 240 NULL values
- violation_precinct: 2 NULL values
- issuing_precinct: 1 NULL value
- feet_from_curb: 1087 NULL values
- vehicle_year: 417 NULL values
---
### Check for duplicate summons numbers
```sql
-- Just get the total number of duplicate summons numbers
SELECT 
    COUNT(*) AS total_duplicate_summons_numbers,
    SUM(duplicate_count) AS total_duplicate_records
FROM (
    SELECT 
        summons_number,
        COUNT(*) AS duplicate_count
    FROM 
        reduced_data
    GROUP BY 
        summons_number
    HAVING 
        COUNT(*) > 1
);
```
[![Screenshot-2025-04-28-at-19-59-48.png](https://i.postimg.cc/X7PHw9Bx/Screenshot-2025-04-28-at-19-59-48.png)](https://postimg.cc/kBxvC6ct)

- Distinct summons number that have been duped: 1,033,989
- Count of all dupe summons numbers: 2,116,843

---
### Checked validity of dates
SQL query to see if the issue date matches any know date format
```sql
WITH date_analysis AS (
  SELECT
    issue_date,
    -- Check for MM/dd/yyyy format
    CASE 
      WHEN regexp_like(issue_date, '^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/[0-9]{4}$')
        AND date_parse(issue_date, '%m/%d/%Y') IS NOT NULL
      THEN 'MM/dd/yyyy'
    
    -- Check for yyyy-MM-dd format
    WHEN regexp_like(issue_date, '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$')
      THEN 'yyyy-MM-dd'
    
    -- Check for MM-dd-yyyy format
    WHEN regexp_like(issue_date, '^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])-[0-9]{4}$')
      THEN 'MM-dd-yyyy'
    
    -- Check for other variations
    WHEN regexp_like(issue_date, '[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}')
      THEN 'Other_slash_format'
    WHEN regexp_like(issue_date, '[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}')
      THEN 'Other_hyphen_format'
    
    -- Check if it's just numbers
    WHEN regexp_like(issue_date, '^[0-9]+$')
      THEN 'Numeric_only'
    
    -- Check for empty/whitespace
    WHEN trim(issue_date) = ''
      THEN 'Empty_string'
    
    -- Catch-all for other patterns
    ELSE 'Unknown_format'
    END AS detected_format
  FROM reduced_data
  WHERE issue_date IS NOT NULL
)

SELECT
  detected_format,
  COUNT(*) AS record_count
FROM date_analysis
GROUP BY detected_format
ORDER BY record_count DESC;
```
[![Screenshot-2025-04-28-at-19-43-54.png](https://i.postimg.cc/nrBz04c7/Screenshot-2025-04-28-at-19-43-54.png)](https://postimg.cc/7JPwLTzY)


### Create table containing records with duplicate summons numbers and invalid dates
```sql
CREATE TABLE invalid_records AS
WITH all_invalid_records AS (
  -- Records with null values in any column
  SELECT *, 'NULL_VALUE' AS invalid_reason
  FROM reduced_data
  WHERE summons_number IS NULL
     OR issue_date IS NULL
     OR plate_id IS NULL
     OR plate_type IS NULL
     OR violation_code IS NULL
     OR violation_description IS NULL
     OR violation_county IS NULL
     OR violation_precinct IS NULL
     OR street_name IS NULL
     OR registration_state IS NULL
     OR vehicle_body_type IS NULL
     OR vehicle_make IS NULL
     OR vehicle_year IS NULL
     OR issuing_agency IS NULL
     OR issuer_squad IS NULL
     OR issuer_precinct IS NULL
  
  UNION ALL
  
  -- Records with invalid dates
  SELECT *, 'INVALID_DATE' AS invalid_reason
  FROM reduced_data
  WHERE issue_date IS NULL
     OR NOT (
       (regexp_like(issue_date, '^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/[0-9]{4}$') AND date_parse(issue_date, '%m/%d/%Y') IS NOT NULL)
       OR regexp_like(issue_date, '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$')
       OR regexp_like(issue_date, '^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])-[0-9]{4}$')
     )
  
  UNION ALL
  
  -- Duplicate summons numbers (all copies)
  SELECT r.*, 'DUPLICATE_SUMMONS' AS invalid_reason
  FROM reduced_data r
  JOIN (
    SELECT summons_number
    FROM reduced_data
    GROUP BY summons_number
    HAVING COUNT(*) > 1
  ) d ON r.summons_number = d.summons_number
)
SELECT 
  i.*,
  (SELECT COUNT(*) FROM (
    SELECT DISTINCT summons_number FROM all_invalid_records
  )) AS total_records_removed
FROM 
  (SELECT DISTINCT * FROM all_invalid_records) i;
```

### Check how many dates are outside the relevant range for analysis 2013-2017
```sql
-- Count records with issue_date before 2013
SELECT 
    'Before 2013' AS period,
    COUNT(*) AS record_count
FROM 
    cleaned_reduced_data
WHERE 
    year(date_parse(issue_date, '%m/%d/%Y')) < 2013

UNION ALL

-- Count records with issue_date after 2017
SELECT 
    'After 2017' AS period,
    COUNT(*) AS record_count
FROM 
    cleaned_reduced_data
WHERE 
    year(date_parse(issue_date, '%m/%d/%Y')) > 2017;

```


### Create a new table with cleaned data (without duplicate summons numbers and invalid issue dates)

```sql
-- Create a new table with cleaned data
CREATE TABLE cleaned_reduced_data AS
WITH 
-- Step 1: Identify summons_numbers that appear only once (non-duplicates)
non_duplicate_summons AS (
  SELECT summons_number
  FROM reduced_data
  GROUP BY summons_number
  HAVING COUNT(*) = 1
),

-- Step 2: Filter for records with valid MM/dd/yyyy date format and within 2013-2017
valid_date_records AS (
  SELECT *
  FROM reduced_data
  WHERE regexp_like(issue_date, '^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/(19|20)[0-9]{2}$')
  AND TO_DATE(issue_date, 'MM/dd/yyyy') BETWEEN TO_DATE('01/01/2013', 'MM/dd/yyyy') AND TO_DATE('12/31/2017', 'MM/dd/yyyy')
)

-- Final selection joining both conditions
SELECT r.*
FROM reduced_data r
JOIN non_duplicate_summons n ON r.summons_number = n.summons_number
WHERE regexp_like(r.issue_date, '^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/(19|20)[0-9]{2}$')
AND TO_DATE(r.issue_date, 'MM/dd/yyyy') BETWEEN TO_DATE('01/01/2013', 'MM/dd/yyyy') AND TO_DATE('12/31/2017', 'MM/dd/yyyy');
```

