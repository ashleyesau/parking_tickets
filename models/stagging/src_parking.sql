
WITH raw_data AS (
    SELECT COUNT(*)
    FROM {{ source('parking_tickets_db', 'reduced_data') }}
)

SELECT *
FROM raw_data
LIMIT 10;