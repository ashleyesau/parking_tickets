# NYC Parking Tickets Data Modeling Project

## Table of Contents

1.  [Overview](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#overview)
2.  [Notes on Data Modeling](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#notes-on-data-modeling)
3.  [Dimensional Model Design](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#dimensional-model-design)
    -   [Date Dimension](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#date-dimension)
    -   [Officer Dimension](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#officer-dimension)
    -   [Vehicle Dimension](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#vehicle-dimension)
    -   [Violation Dimension](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#violation-dimension)
4.  [Fact Table](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#fact-table)
5.  [Implementation Details](https://claude.ai/chat/4f354dc7-0d68-412a-9696-b236d92558e8#implementation-details)

## Overview

This project implements a dimensional data model for analyzing New York City parking ticket data. The model follows a star schema design with a central fact table (`fact_parking_tickets`) connected to four dimension tables:

-   `dim_date`: Time-based analysis dimensions
-   `dim_officer`: Information about ticket issuers
-   `dim_vehicle`: Vehicle characteristics
-   `dim_violation`: Violation types and locations

The model is implemented using SQL within a dbt framework, enabling efficient querying for parking violation analysis across multiple dimensions. This dimensional approach allows for flexible reporting and analytics across time periods, locations, vehicle types, and violation categories.


## Notes on Data Modeling

For the purposes of this project, I needed to convert abbreviated fields in the raw dataset into more meaningful and human-readable formats. This included:

-   **Borough Names**: Translating abbreviated borough codes into full borough names (e.g., "BK" → "Brooklyn").
-   **Plate Type**: Mapping coded plate types to descriptive labels (e.g., "PAS" → "Passenger").
-   **Precinct**: Converting numeric or short codes into full precinct names or IDs where applicable.

### Data Quality Management

-   **Null Handling Strategy**: Applied consistent approaches for handling NULL values, using domain-appropriate defaults (e.g., 'UNKNOWN AGENCY' for missing agencies, 'UNKNOWN MAKE' for vehicles)
-   **Empty String Treatment**: Distinguished between NULL values and empty strings, treating them differently where appropriate
-   **Validation Rules**: Implemented boundary checks for numeric fields (e.g., rejecting vehicle years before 1900 or after current year)
-   **Core Record Filtering**: Established data integrity by excluding records with missing critical values (summons_number, issue_date, violation_code) from the fact table

### Data Standardization

-   **Case Normalization**: Applied UPPER() or INITCAP() functions consistently across text fields to ensure uniformity
-   **Whitespace Management**: Used TRIM() functions to eliminate leading/trailing spaces that could affect joins and analysis
-   **Abbreviation Expansion**: Transformed abbreviated values to their full forms (e.g., 'TOY' → 'TOYOTA', 'SUV' → 'SPORT UTILITY VEHICLE')
-   **Code Translation**: Converted numeric or coded values into human-readable descriptions

### Dimensional Techniques

-   **Surrogate Keys**: Generated MD5 hash-based surrogate keys for dimension tables where natural keys weren't available
-   **Slowly Changing Dimensions**: Prepared for potential historical tracking (particularly in vehicle and violation dimensions)
-   **Hierarchical Dimensions**: Created multi-level categorizations (e.g., violation severity, vehicle age groups)
-   **Flag Creation**: Added boolean indicators for special conditions (weekend dates, commercial vehicles, time-sensitive violations)
-   **Pattern Recognition**: Used regular expressions to detect and categorize violation description patterns

### Analytical Enhancements

-   **Derived Metrics**: Added computed fields to support common analytical scenarios (e.g., vehicle_age_category)
-   **Enriched Categories**: Created detailed categorizations beyond the raw data (e.g., detailed_violation_category, violation_specificity)
-   **Text Normalization**: Standardized street names and location information for geographic analysis
-   **Time Intelligence**: Built comprehensive date dimension with calendar hierarchies, fiscal periods, and special day flags
## Dimensional Model Design

### Date Dimension

```sql
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

```

_What this code does:_ This section creates a calendar table that helps analyze tickets by different time periods. It takes all the dates from our ticket data and adds useful information like:

-   Year, month, and day numbers
-   Day of the week and month names
-   Special day flags (weekends, holidays)
-   Fiscal year information
-   First and last days of each month and year

This allows us to easily answer questions like "How many tickets were issued on weekends?" or "What months have the highest ticket volume?"

### Officer Dimension

```sql
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

```

_What this code does:_ This section creates a table that organizes information about the officers or agencies that issue parking tickets. It:

-   Creates a unique ID for each issuing entity
-   Standardizes agency names (making sure they're all in the same format)
-   Handles missing information about squads by assigning them to "UNASSIGNED" or "UNSPECIFIED" categories
-   Cleans up precinct numbers for consistency

This allows us to analyze which agencies issue the most tickets or identify patterns in enforcement by different precincts or squads.

### Vehicle Dimension

```sql
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


```

_What this code does:_ This section builds a table containing all the unique vehicles that received tickets in our dataset. It:

-   Creates a unique vehicle ID for each combination of plate, type, make, etc.
-   Standardizes vehicle information (like expanding "TOY" to "TOYOTA")
-   Categorizes vehicles by age (new, used, older, vintage)
-   Standardizes state abbreviations (e.g., "NEW YORK" becomes "NY")
-   Fills in missing values with appropriate placeholders

This allows us to analyze which types of vehicles receive the most tickets or if certain makes/models are ticketed more frequently than others.

### Violation Dimension

```sql
{{
  config(
    materialized = 'table'
  )
}}

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
  WHERE 
    -- First, filter out clearly irrelevant records
    violation_code IS NOT NULL
    AND violation_code != 0
    AND violation_description != 'UNKNOWN VIOLATION'
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
    END AS violation_county,

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

    -- Enhanced violation specificity (now using code patterns)
    CASE
      WHEN violation_description IS NULL THEN 'UNKNOWN'
      WHEN violation_description ~ '^\d{2,3}[a-zA-Z]?-.*' THEN 'SPECIFIC' -- Codes with numbers and optional letters
      WHEN violation_description ~ '^\d{2,3}[a-zA-Z]?$' THEN 'GENERAL' -- Just codes without description
      WHEN violation_description = 'UNSPECIFIED VIOLATION' THEN 'GENERIC'
      ELSE 'AMBIGUOUS'
    END AS violation_specificity,

    -- New: Detailed violation category
    CASE
      WHEN violation_description ~* 'hydrant|fire lane|emergency' THEN 'SAFETY_CRITICAL'
      WHEN violation_description ~* 'expired|sticker|registration|plate|display|mutilated|counterfeit' THEN 'DOCUMENTATION'
      WHEN violation_description ~* 'no parking|no stand|no stopping' THEN 'PARKING_RESTRICTION'
      WHEN violation_description ~* 'double park|angle park|marked space|traffic lane' THEN 'POSITIONING'
      WHEN violation_description ~* 'crosswalk|sidewalk|pedestrian ramp|safety zone|intersection' THEN 'PEDESTRIAN_AREA'
      WHEN violation_description ~* 'bus|commercial|midtown|for-hire' THEN 'COMMERCIAL_VEHICLE'
      WHEN violation_description ~* 'meter|municipal receipt|feeding meter' THEN 'METER_RELATED'
      WHEN violation_description ~* 'obstruct|blocking|excavation' THEN 'OBSTRUCTION'
      ELSE 'OTHER'
    END AS detailed_violation_category,

    -- New: Severity level
    CASE
      WHEN violation_description ~* '40-Fire Hydrant|50-Crosswalk|51-Sidewalk|09-Blocking The Box|98-Obstructing Driveway' THEN 'HIGH'
      WHEN violation_description ~* '46a-Double Parking|46b-Double Parking|61-Wrong Way|67-Blocking Ped. Ramp' THEN 'MEDIUM'
      WHEN violation_description ~* 'expired|sticker|registration' THEN 'LOW'
      ELSE 'MODERATE'
    END AS severity_level,

    -- New: Commercial vehicle flag
    CASE
      WHEN violation_description ~* 'commercial|com plate|com veh|bus|taxi|for-hire' THEN TRUE
      ELSE FALSE
    END AS involves_commercial_vehicle,

    -- New: Time sensitive violation flag
    CASE
      WHEN violation_description ~* 'street clean|time limit|overtime|nighttime' THEN TRUE
      ELSE FALSE
    END AS time_sensitive_violation

  FROM violation_source
)

SELECT * FROM violation_cleaned

```

_What this code does:_ This section creates a table that enriches information about each type of violation. It:

-   Makes violation codes and descriptions consistent
-   Converts county codes to full names (e.g., "BK" to "Brooklyn")
-   Categorizes violations by type (parking, traffic, etc.)
-   Adds a severity level (high, medium, low) to each violation
-   Flags violations involving commercial vehicles
-   Identifies time-sensitive violations (like street cleaning)
-   Standardizes street names and identifies street types

This enriched information helps us understand patterns in the types of violations issued and where they occur most frequently.

## Fact Table
```sql
{{
  config(
    materialized = 'table',
    dist_key = 'summons_number'
  )
}}

SELECT
  -- Core identifiers
  CAST(summons_number AS BIGINT) AS summons_number,
  CAST(issue_date AS DATE) AS issue_date,
  
  -- Vehicle information
  TRIM(plate_id) AS plate_id,
  TRIM(plate_type) AS plate_type,
  UPPER(TRIM(registration_state)) AS registration_state,
  TRIM(vehicle_body_type) AS vehicle_body_type,
  TRIM(vehicle_make) AS vehicle_make,
  CAST(vehicle_year AS SMALLINT) AS vehicle_year,
  
  -- Violation details
  CAST(violation_code AS INTEGER) AS violation_code,
  TRIM(violation_description) AS violation_description,
  UPPER(TRIM(violation_county)) AS violation_county,
  CAST(violation_precinct AS SMALLINT) AS violation_precinct,
  TRIM(street_name) AS street_name,
  
  -- Issuer information
  UPPER(TRIM(issuing_agency)) AS issuing_agency,
  TRIM(issuer_squad) AS issuer_squad,
  CAST(issuer_precinct AS SMALLINT) AS issuer_precinct,
  
  -- Simple metric
  1 AS ticket_count
FROM 
  reduced_data
WHERE
  summons_number IS NOT NULL
  AND issue_date IS NOT NULL
  AND violation_code IS NOT NULL

```

_What this code does:_ This section creates our main ticket data table that connects all the dimension tables together. It:

-   Cleans and formats all the core ticket information
-   Ensures consistent data types for each field
-   Filters out incomplete records (those missing ticket numbers, dates, or violation codes)
-   Adds a simple count field (1 for each ticket) to make counting tickets easier

This central table allows us to connect all our dimensions together for comprehensive analysis of the parking ticket data.

## Implementation Details

This data model is implemented using dbt (data build tool), which provides:

-   Version control for SQL transformations
-   Modular approach to building data pipelines
-   Table dependencies and automated build order
-   Materialization options (tables, views, etc.)
-   Testing capabilities for data quality assurance

The model runs on a dbt and Redshift, enabling efficient analysis of parking violation patterns across New York City. This approach allows both technical and business users to access insights about parking enforcement trends and violation patterns throughout the city.
