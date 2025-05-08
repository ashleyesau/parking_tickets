# Data Checks on Raw Data in Athena
This document outlines the process for **cleaning** and **validating** raw data using **Amazon Athena**. It includes steps for selecting relevant **columns**, checking **data quality** (e.g., handling **NULL values**, **duplicates**, and **invalid dates**), and ensuring that the data is ready for further processing. The goal is to ensure **clean**, reliable data that can be used for **analysis** and **modeling** in downstream tasks.

## Table of Contents

### 1. Data Selection & Renaming
1. [Created New Table with Only Relevant Columns (Renamed Variables to Include Underscores)](#created-new-table-with-only-relevant-columns-renamed-variables-to-include-underscores)

### 2. Initial Data Validation
2. [Checked counts of rows and columns of both tables to ensure a match](#checked-counts-of-rows-and-columns-of-both-tables-to-ensure-a-match)
3. [Count the Number of Columns in raw_data vs reduced_data](#count-the-number-of-columns-in-raw_data-vs-reduced_data)

### 3. Data Quality Checks
4. [Identified which columns have NULL values](#identified-which-columns-have-null-values)
5. [Check for duplicate summons numbers](#check-for-duplicate-summons-numbers)
6. [Checked validity of dates](#checked-validity-of-dates)
7. [Check how many dates are outside the relevant range for analysis 2013-2017](#check-how-many-dates-are-outside-the-relevant-range-for-analysis-2013-2017)

### 4. Cleaning & Output
8. [Create table containing records with duplicate summons numbers and invalid dates](#create-table-containing-records-with-duplicate-summons-numbers-and-invalid-dates)
9. [Create a new table with cleaned data (without duplicate summons numbers and invalid issue dates)](#create-a-new-table-with-cleaned-data-without-duplicate-summons-numbers-and-invalid-issue-dates)

### Created New Table with Only Relevant Columns (Renamed Variables to Include Underscores)

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

**Notes:**
This query creates a new table called `reduced_data` from the raw data with these key operations:
- Selects only the essential columns needed for analysis (reducing the dataset size)
- Renames all columns to use underscores instead of spaces for better SQL compatibility
- Stores the new table in Parquet format (a columnar storage format optimized for analytics)
- Saves the output to an S3 bucket location for future access

### Checked counts of rows and columns of both tables to ensure a match

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

**Notes:**
This query performs a basic data validation check by:
- Counting the total number of rows in both the raw and reduced tables
- Calculating the difference between these counts
- Creating a validation status field that shows "MATCH" if the counts are identical or "MISMATCH" if they differ
- The screenshot confirms both tables have the same number of rows (42,339,438), verifying no data was lost during the column reduction process

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

**Notes:**
This query goes a step further in validation by:
- Comparing the non-NULL counts for specific important columns (summons_number, issue_date, violation_code) 
- Checking that the column renaming process didn't impact data quality
- Using UNION ALL to combine the results for multiple columns into a single result set
- The screenshot shows that all counts match perfectly across the tables, confirming successful data transfer

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
**Notes:**
This query examines the schema-level differences between the tables by:
- Querying the Athena information_schema to count total columns in each table
- Using Common Table Expressions (CTEs) to organize the query logic
- Computing the difference to see how many columns were removed
- The raw_data table had 51 columns while reduced_data has 16 columns.

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

**Notes:**
This query identifies data quality issues by:
- Counting NULL values in each column using the COUNT(*) - COUNT(column_name) technique
- Including the total record count for context
- The results reveal several columns with NULL values
- These NULL values need to be addressed in the data cleaning process

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

**Notes:**
This query identifies duplicate records in the dataset by:
- Using a subquery to find summons_number values that appear more than once
- Counting how many distinct summons numbers are duplicated
- Calculating the total number of records involved in duplication
- The screenshot shows significant duplication issues:
  - 1,033,989 distinct summons numbers have duplicates
  - 2,116,843 total records are part of duplicate sets
- This is a major data quality issue since summons numbers should be unique identifiers

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

**Notes:**
This query analyzes date formats in the dataset by:
- Using regular expressions to identify different date formats (MM/dd/yyyy, yyyy-MM-dd, etc.)
- Creating a CTE (Common Table Expression) to categorize each record's date format
- Counting how many records fall into each format category
- The screenshot shows that the vast majority of dates (42,339,198) use the MM/dd/yyyy format
- This information is crucial for proper date parsing and filtering in subsequent queries

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

**Notes:**
This query creates a new table to track invalid records by:
- Identifying three main categories of invalid data:
  1. Records with NULL values in any column
  2. Records with invalid date formats
  3. Records with duplicate summons numbers
- Using UNION ALL to combine all problem records into one result set
- Adding an "invalid_reason" column to track why each record was flagged as invalid
- Calculating a total count of distinct summons numbers that will be removed
- Creating a permanent table to store these invalid records for auditing purposes

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

**Notes:**
This query analyzes temporal coverage of the data by:
- Parsing the issue_date field and extracting just the year component
- Counting records that fall outside the target analysis period (2013-2017)
- Using UNION ALL to combine the "too early" and "too late" results into one result set
- These counts help determine how many records will be filtered out due to date range constraints
- This information is important for understanding what portion of the data will be used in the final analysis

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

**Notes:**
This query creates a cleaned dataset by:
- Using CTEs to organize the filtering logic into clear steps
- First identifying summons numbers that appear exactly once (removing duplicates)
- Then filtering for date validity using regular expressions and date parsing
- Restricting the dataset to only records from 2013-2017
- Combining these conditions to create a new cleaned table for analysis
- This query represents the culmination of the data cleaning process, producing a dataset with uniquely identified records and valid dates within the time range of interest

### Create new version of reduced_data table 
This has only valid data
```sql
CREATE TABLE cleaned_reduced_data AS
WITH non_duplicate_summons AS (
  SELECT summons_number
  FROM reduced_data
  GROUP BY summons_number
  HAVING COUNT(*) = 1
),

valid_date_records AS (
  SELECT summons_number
  FROM reduced_data
  WHERE regexp_like(issue_date, '^(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/(19|20)[0-9]{2}$')
    AND TRY(date_parse(issue_date, '%m/%d/%Y')) BETWEEN DATE '2013-01-01' AND DATE '2017-12-31'
),

valid_violation_records AS (
  SELECT summons_number
  FROM reduced_data
  WHERE violation_code IS NOT NULL
),

valid_plate_records AS (
  SELECT summons_number
  FROM reduced_data
  WHERE plate_id IS NOT NULL 
    AND trim(plate_id) != ''
),

valid_plate_types AS (
  SELECT summons_number
  FROM reduced_data
  WHERE plate_type IS NOT NULL 
    AND trim(plate_type) != ''
),

county_counts AS (
  SELECT 
    violation_county,
    COUNT(*) AS county_count
  FROM reduced_data
  WHERE violation_county IS NOT NULL
    AND trim(violation_county) != ''
  GROUP BY violation_county
  HAVING COUNT(*) > 100000
),

valid_counties AS (
  SELECT rd.summons_number
  FROM reduced_data rd
  JOIN county_counts cc
    ON rd.violation_county = cc.violation_county
  WHERE rd.violation_county IS NOT NULL
    AND trim(rd.violation_county) != ''
)

SELECT r.*
FROM reduced_data r
JOIN non_duplicate_summons nd ON r.summons_number = nd.summons_number
JOIN valid_date_records vd ON r.summons_number = vd.summons_number
JOIN valid_violation_records vv ON r.summons_number = vv.summons_number
JOIN valid_plate_records vpr ON r.summons_number = vpr.summons_number
JOIN valid_plate_types vpt ON r.summons_number = vpt.summons_number
JOIN valid_counties vc ON r.summons_number = vc.summons_number;
```

**Notes:**
This query creates a more thoroughly cleaned dataset by:
- Implementing a comprehensive set of data quality filters through multiple CTEs:
  1. Removing duplicate summons numbers
  2. Ensuring dates are valid and within the 2013-2017 range
  3. Filtering out records with NULL violation codes
  4. Requiring valid plate IDs and types (non-NULL and non-empty)
  5. Including only counties with substantial data (>100,000 records)
- Using multiple JOIN operations to apply all these filters simultaneously
- Using TRY() function with date_parse to handle possible date parsing errors
- This creates the final cleaned dataset ready for analytical use, with all major data quality issues addressed
