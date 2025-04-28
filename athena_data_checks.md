
# Data Checks on Raw Data in Athena

---

## Created New Table with Only Relevant Columns (Renamed Variables to Include Underscores)

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
  "violation code" AS violation_code,
  "violation description" AS violation_description,
  "violation time" AS violation_time,
  "violation county" AS violation_county,
  "violation precinct" AS violation_precinct,
  "vehicle make" AS vehicle_make,
  "street name" AS street_name,
  "hydrant violation" AS hydrant_violation,
  "double parking violation" AS double_parking_violation,
  "feet from curb" AS feet_from_curb,
  "issuing agency" AS issuing_agency,
  "issuer squad" AS issuer_squad,
  "issuer precinct" AS issuer_precinct
FROM raw_data;
```

### Ran Some Queries
Ensured total records are still the same between raw and reduced table (Total raw records: 42,339,438)

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
