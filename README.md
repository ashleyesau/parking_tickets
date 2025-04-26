# parking_tickets
ELT pipeline using NYC parking ticket data from Kaggle

# NYC Parking Tickets Data Pipeline

This project is a data engineering pipeline that processes 42 million NYC parking ticket records. It demonstrates end-to-end data handling using AWS services and prepares the data for modeling in **dbt** and **Redshift**.

---

## Project Goals

- Build a robust, modular data pipeline
- Clean and validate raw public sector data at scale
- Prepare data for efficient querying and analytics
- Practice cloud-native data engineering tools

---

## Tech Stack

| Tool          | Purpose                                 |
|---------------|------------------------------------------|
| S3            | Raw & cleaned data storage               |
| AWS Glue      | Schema inference, ETL with PySpark       |
| Athena        | Query raw data for validation            |
| PySpark       | Data cleaning and transformation         |
| Redshift      | Cloud data warehouse                     |
| dbt           | Data modeling and testing                |

---

## Data Overview

**Source**: 4 NYC Parking Ticket CSVs  
**Volume**: ~42 million rows  
**Fields**: 43 columns per record including:

- `summons_number`
- `plate_id`
- `issue_date`
- `violation_code`
- `vehicle_make`
- `violation_description`
- ...and more.

---

## Phase 1: Ingest & Clean (In Progress)

| Step | Description | Status |
|------|-------------|--------|
| 1    | Upload raw CSVs to S3 | ✅ Done |
| 2    | Use AWS Glue Crawler to infer schema | ✅ Done |
| 3    | Explore data in Athena and identify issues | ✅ Done |
| 4    | Write Glue PySpark job to clean the data | 🔄 In Progress |
| 5    | Output cleaned data to S3 in Parquet format | 🔜 Next |

---

## Cleaning Logic

Planned transformations using PySpark in AWS Glue:

- Drop rows with missing `summons_number`
- Convert `issue_date` to proper date format
- Trim and lowercase key string fields
- Filter out unrealistic `vehicle_year` values
- Output to Parquet for performance

---

## Next Phases

### Phase 2: Load & Model

- [ ] Load cleaned Parquet data into Redshift
- [ ] Create data models in dbt
- [ ] Test assumptions and document schema
- [ ] Generate sample reports or dashboards

---

## Lessons Learned (so far)

- AWS Glue Crawler is powerful for schema inference but not perfect — always validate.
- Partitioning and file format choices matter when scaling to tens of millions of rows.
- Early data exploration in Athena is critical before modeling.

---

## Notes

This project is designed to run **once** for now (batch ETL), but future iterations may include scheduling or DAG orchestration with tools like Airflow.

---

