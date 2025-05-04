WITH raw_data AS (
    SELECT
        summons_number,
        issue_date,
        plate_id,
        plate_type,
        violation_code,
        violation_description,
        violation_county,
        violation_precinct,
        street_name,
        registration_state,
        vehicle_body_type,
        vehicle_make,
        vehicle_year,
        issuing_agency,
        issuer_squad,
        issuer_precinct
    FROM {{ source('parking_tickets_db', 'reduced_data') }}
)

SELECT
    summons_number,
    issue_date,
    plate_id,
    plate_type,
    violation_code,
    violation_description,
    violation_county,
    violation_precinct,
    street_name,
    registration_state,
    vehicle_body_type,
    vehicle_make,
    vehicle_year,
    issuing_agency,
    issuer_squad,
    issuer_precinct
FROM raw_data
