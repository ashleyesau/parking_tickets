
WITH raw_data AS (
    SELECT *
    FROM {{ source('parking_tickets_db', 'reduced_data') }}
)
