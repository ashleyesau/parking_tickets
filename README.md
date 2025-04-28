# End-to-end Data Engineering Pipeline using NYC Parking Ticket Data

Welcome to my NYC Parking Tickets Data Pipeline project!

This project represents a major milestone in my journey as a data engineer - bringing together everything I've been learning about cloud-native tools, data modeling, and building scalable pipelines. It started with a real-world dataset of over 42 million parking ticket records from New York City, and became an opportunity to practice designing a robust, modular data system from raw ingestion to clean, analytics-ready data and visualised insights.

I challenged myself to approach this like a real-world data engineering project:

-   **Working with messy public sector data at scale**
    
-   **Building quality checks and validation processes into the pipeline**
    
-   **Modeling and transforming the data for efficient analytics**
    
-   **Leveraging a modern cloud tech stack: AWS S3, Glue, Athena, Redshift, dbt, and Looker**
    

I was especially excited to bring everything together - not just building the pipeline but designing it thoughtfully: ensuring each phase flowed cleanly into the next, solving unexpected problems along the way, and ending with a functional, polished analytics environment. It’s a project I’m proud of because it doesn't just show technical skills - it shows how much care, learning, and passion I bring into my work.

Thank you for taking a look! I'm excited to keep building, improving, and taking on even bigger challenges ahead.

# Table of Contents

- [Project Goals](#project-goals)
- [Tech Stack](#tech-stack)
 - [Overview of the NYC Parking Tickets Dataset](#overview-of-the-nyc-parking-tickets-dataset)
 - [Questions This Pipeline Answers](#questions-this-pipeline-answers)
- [Phase One: Data Ingestion, Quality Checks, and Cleaning](#phase-one-data-ingestion-quality-checks-and-cleaning)
  - [Overview](#overview)
  - [Detailed Steps and Processes](#detailed-steps-and-processes)
  - [Challenges Faced and Solutions Implemented](#challenges-faced-and-solutions-implemented)
- [Phase Two: Data Modeling](#phase-two-data-modeling)
  - [Overview](#overview-1)
  - [Schema Design and Implementation](#schema-design-and-implementation)
  - [Transformation Logic](#transformation-logic)
  - [Testing and Validation](#testing-and-validation)
- [Phase Three: Data Visualisation](#phase-three-data-visualisation)
  - [Overview](#overview-2)
  - [Tool Selection and Setup](#tool-selection-and-setup)
  - [Dashboard Design and Implementation](#dashboard-design-and-implementation)
- [Lessons Learned](#lessons-learned)
  - [Key Takeaways](#key-takeaways)
  - [Reflection on Challenges and Successes](#reflection-on-challenges-and-successes)
  - [Recommendations for Future Projects](#recommendations-for-future-projects)


# Project Goals
This project aimed to design a robust, modular data pipeline for NYC Parking Ticket data. My key goals were:

-   Define key questions and shape the pipeline to support answering them effectively.
    
-   Build a scalable, cloud-native pipeline using AWS S3, Glue, Athena, Redshift, dbt, and Looker.
    
-   Clean, validate, and transform messy public sector data at scale.
    
-   Model the data for fast, efficient querying and analytics.
    
-   Strengthen my real-world skills in cloud data engineering and pipeline design.

# Tech Stack

| Tool           | Purpose                                  |
|----------------|------------------------------------------|
| AWS S3         | Raw & cleaned data storage               |
| AWS Glue       | Schema inference, ETL with PySpark       |
| AWS Athena     | Query raw data for validation            |
| AWS Redshift   | Cloud data warehouse                     |
| dbt (Data Build Tool)           | Data modeling and testing                |
| Looker         | Data visualization  |


# Overview of the NYC Parking Tickets Dataset
This dataset contains **42 million NYC parking ticket records**, capturing violations issued across the city. It includes over 50 fields that capture details like **violation type**, **location**, **vehicle make**, **issue date**, and more, offering a solid foundation for analysis on parking behaviour, enforcement trends, and patterns across time and space.

# Questions This Pipeline Answers
-   **Issuing Agencies and Squads:** Which agencies and squads issue the most tickets?  
    (Analyze by **issuing agency**, **issuer squad**, and **issuer precinct**.)

-   **Violation Types:** What types of violations are most common?  
    (Break down by **violation code** and **violation description**.)
    
  -   **Violation Locations:** Where are violations most frequent?  
    (Analyze by **violation county**, **violation precinct**, and **street name**.)
    
-   **Violation Timing:** When are parking violations happening?  
    (Analyze ticket counts by **issue date** and **violation time**.)
    
-   **Vehicle Makes:** What car brands are most often ticketed?  
    (Analyze by **vehicle make**.)
    
-   **Special Violation Types:** How common are hydrant or double parking violations?  
    (Focus on **hydrant violation** and **double parking violation**.)

-   **Parking Distance:** Is there any trend between distance from curb and ticketing?  
    (Explore using **feet from curb**.)
    
# Phase One: Data Ingestion, Quality Checks, and Cleaning
## Overview
In Phase One, I focused on building a solid foundation for the pipeline by carefully ingesting, validating, and preparing the raw NYC parking ticket data.

Starting with 42 million records across four years (2014–2017), I loaded the raw CSV files into Amazon S3, then used AWS Glue to automatically infer the schema and organize the data into a centralized database. Early validation using AWS Athena helped surface quality issues and guide cleanup efforts before moving forward to modeling.

This phase was all about **laying the groundwork for scale**:  
- Organizing messy real-world data  
- Catching early data quality pitfalls  
- Setting up a clean, queryable foundation for the next stages
## Detailed Steps and Processes

### 1. Load Raw Data into Amazon S3

-   Downloaded the raw NYC parking tickets dataset in **CSV** format from Kaggle.
    
-   Loaded four CSV files into an Amazon S3 bucket, covering **2014–2017**.
    
-   Each year’s file contained approximately **10 million rows**, totaling around **42 million records**.
    

Kaggle view of NYC Parking Tickets dataset: [![Screenshot-2025-04-26-at-08-22-03.png](https://i.postimg.cc/wMPt2Bkn/Screenshot-2025-04-26-at-08-22-03.png)](https://postimg.cc/2LQ88rMx)

View of the bucket structure in S3: [![Screenshot-2025-04-26-at-08-29-43.png](https://i.postimg.cc/hhWDhQs4/Screenshot-2025-04-26-at-08-29-43.png)](https://postimg.cc/K3fSHzCC)

----------

### 2. Infer Schema Using AWS Glue Crawler

-   Created an **AWS Glue Crawler** to scan the four CSV files and **automatically infer the schema**.
    
-   Configured the crawler to:
    
    -   Combine all four CSV files into a **single table** (since they had identical schemas).
        
    -   Store the inferred schema in a **new Glue database** for easier access and querying.
        

Crawler setup example: [![Screenshot-2025-04-26-at-09-21-39.png](https://i.postimg.cc/QVGfPj8n/Screenshot-2025-04-26-at-09-21-39.png)](https://postimg.cc/zH7wHZRn)

Resulting database and table: [![Screenshot-2025-04-26-at-09-25-29.png](https://i.postimg.cc/L41KyXvD/Screenshot-2025-04-26-at-09-25-29.png)](https://postimg.cc/dDwx3JbZ)

----------

### 3. Explore and Validate Data Quality in Athena

After setting up the combined table with AWS Glue, I used **AWS Athena** to query the dataset and perform critical data validation before moving deeper into modeling and transformation.

Out of 50+ original columns in the raw dataset, I identified 15 **core columns** that would drive the analysis and pipeline design. My data quality checks focused primarily on these key fields:

1.  `summons number` (Unique ID, needed for counting)
2. `issue date` (Time-based analysis)
3. `violation code` (Type of violation - numeric)
4. `violation description` (Human-readable type)
5. `violation time` (Peak hours analysis)
6. `violation county` (Area grouping)
7. `violation precinct` (Area grouping)
8. `vehicle make` (Car brand analysis)
9. `street name` (Location analysis)
10. `hydrant violation` (Special violation type)
11. `double parking violation` (Special violation type)
12. `feet from curb` (Distance analysis)
13. `issuing agency` (Issuer-level analysis)
14.  `issuer squad` (Squad analysis)
15. `issuer precinct` (Connect squad to precinct)
        

## Challenges Faced and Solutions Implemented
Challenges: In the key fields required for analysis, there were some issues like invalid data format, null values for dates, and null and duplicate values for summons number, which is the unique identifier of records in this dataset.

## Lessons Learned (so far)

-   **AWS Glue Crawlers** are powerful for schema inference but not perfect — **always validate the results** manually.
    
-   **Partitioning** and **optimized file formats** (e.g., Parquet) become increasingly important when working with **tens of millions of rows**.
    
-   **Early data exploration in Athena** is crucial for catching quality issues before moving into modeling and transformations.
-----------
# Phase Two: Data Modeling
## Overview
## Schema Design and Implementation
## Transformation Logic
## Testing and Validation

# Phase Three: Data Visualisation
## Overview
## Tool Selection and Setup
## Dashboard Design and Implementation

# Lessons Learned
## Key Takeaways
## Reflection on Challenges and Successes
## Recommendations for Future Projects
