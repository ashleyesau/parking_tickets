# End-to-end Data Engineering Pipeline using NYC Parking Ticket Data

Welcome to my NYC Parking Tickets Data Pipeline project!

This project represents a major milestone in my journey as a data engineer - bringing together everything I've been learning about cloud-native tools, data modeling, and building scalable pipelines. It started with a real-world dataset of over **42 million parking ticket records** from New York City, and became an opportunity to practice designing a robust, modular data system **from raw ingestion to clean, analytics-ready data and visualised insights.**

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
- [Key Questions](#key-questions)  
- **Phase One: Data Ingestion, Quality Checks, and Cleaning**  
  - [Overview of phase one](#overview-of-phase-one)  
  - [Steps and Processes](#steps-and-processes)  
    - [Load Raw Data into Amazon S3](#load-raw-data-into-amazon-s3)  
    - [Infer Schema Using AWS Glue Crawler](#infer-schema-using-aws-glue-crawler)  
    - [Exploring and Validating Data Quality in Athena](#exploring-and-validating-data-quality-in-athena)  
    - [How I Checked the Data](#how-i-checked-the-data)  
    - [Handling Invalid Records](#handling-invalid-records)  
- **Phase Two: Data Modeling**  
  - [Overview of phase two](#overview-of-phase-two)  
  - [Schema Design and Implementation](#schema-design-and-implementation)  
  - [Transformation Logic](#transformation-logic)  
  - [Testing and Validation](#testing-and-validation)  
- **Phase Three: Data Visualisation**  
  - [Overview of phase three](#overview-of-phase-three)  
  - [Dashboard Design and Implementation](#dashboard-design-and-implementation)  
- [Lessons Learned](#lessons-learned)  

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

# Key Questions
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
## Overview of phase one
In Phase One, I focused on building a solid foundation for the pipeline by carefully ingesting, validating, and preparing the raw NYC parking ticket data.

Starting with 42 million records across four years (2014–2017), I loaded the raw CSV files into Amazon S3, then used AWS Glue to automatically infer the schema and organize the data into a centralized database. Early validation using AWS Athena helped surface quality issues and guide cleanup efforts before moving forward to modeling.

This phase was all about **laying the groundwork for scale**:  
- Organizing messy real-world data  
- Catching early data quality pitfalls  
- Setting up a clean, queryable foundation for the next stages
## Steps and Processes

### Load Raw Data into Amazon S3

-   Downloaded the raw NYC parking tickets dataset in **CSV** format from Kaggle.
    
-   Loaded four CSV files into an Amazon S3 bucket, covering **2014–2017**.
    
-   Each year’s file contained approximately **10 million rows**, totaling around **42 million records**.
    

Kaggle view of NYC Parking Tickets dataset: [![Screenshot-2025-04-26-at-08-22-03.png](https://i.postimg.cc/wMPt2Bkn/Screenshot-2025-04-26-at-08-22-03.png)](https://postimg.cc/2LQ88rMx)

View of the bucket structure in S3: [![Screenshot-2025-04-26-at-08-29-43.png](https://i.postimg.cc/hhWDhQs4/Screenshot-2025-04-26-at-08-29-43.png)](https://postimg.cc/K3fSHzCC)

----------

### Infer Schema Using AWS Glue Crawler

-   Created an **AWS Glue Crawler** to scan the four CSV files and **automatically infer the schema**.
    
-   Configured the crawler to:
    
    -   Combine all four CSV files into a **single table** (since they had identical schemas).
        
    -   Store the inferred schema in a **new Glue database** for easier access and querying.
        

Crawler setup example: [![Screenshot-2025-04-26-at-09-21-39.png](https://i.postimg.cc/QVGfPj8n/Screenshot-2025-04-26-at-09-21-39.png)](https://postimg.cc/zH7wHZRn)

Resulting database and table: [![Screenshot-2025-04-26-at-09-25-29.png](https://i.postimg.cc/L41KyXvD/Screenshot-2025-04-26-at-09-25-29.png)](https://postimg.cc/dDwx3JbZ)

----------


### Exploring and Validating Data Quality in Athena

Once I had set up the combined table in AWS Glue, it was time to roll up my sleeves and dive into **AWS Athena** for some hands-on data validation.

The raw dataset came with over 50 columns, but not all of them were equally useful. After exploring the structure and content, I narrowed it down to **15 core fields** that would really drive the insights and future modeling work:

| # | Column | Purpose |
|:--|:-------|:--------|
| 1 | `summons number` | Unique ticket identifier |
| 2 | `issue date` | Time-based analysis |
| 3 | `violation code` | Numeric type of violation |
| 4 | `violation description` | Human-readable violation type |
| 5 | `violation time` | Peak hour analysis |
| 6 | `violation county` | Regional grouping |
| 7 | `violation precinct` | Localized area grouping |
| 8 | `vehicle make` | Brand analysis |
| 9 | `street name` | Location-based analysis |
| 10 | `hydrant violation` | Special violation type |
| 11 | `double parking violation` | Special violation type |
| 12 | `feet from curb` | Distance validation |
| 13 | `issuing agency` | Agency-level analysis |
| 14 | `issuer squad` | Squad-level patterns |
| 15 | `issuer precinct` | Ties squad to geography |

---

### How I Checked the Data

I didn't just want the data to *exist* - I needed it to be **trustworthy**. So, I designed a few key quality checks:

- **Are the critical fields populated?**  
  I made sure important columns like `summons number`, `issue date`, and `violation code` weren't missing values.

- **Where are the gaps?**  
  I queried for `NULL`s and blank values to understand if any fields were unreliable.

- **Is the data actually usable?**  
  Dates needed to be parsable as timestamps. Times needed to be in a consistent format. Anything weird could break later transformations.

- **Did Glue infer the schema correctly?**  
  I cross-checked the types against the original files. (It caught a few surprises, like numbers being read as strings.)

- **Are there duplicate tickets?**  
  `summons number` should be unique - duplicates would skew any counts.

- **Anything suspicious?**  
  I flagged odd cases like:
  - Negative distances in `feet from curb`
  - Strange `violation times`
  - Typos or strange names in `vehicle make`

---

### Handling Invalid Records

Instead of just deleting messy records and moving on, I decided to **capture them properly**.

- I created a **separate table** to store all invalid or suspicious records.
- For every dropped record, I logged:
  - The full raw record
  - The reason it was considered invalid (e.g., missing critical field, invalid timestamp, duplicate ID)

This way, the main dataset stayed clean, but no data was ever truly "lost" - just archived for transparency and auditability.




-----------
# Phase Two: Data Modeling
## Overview of phase two
## Schema Design and Implementation
## Transformation Logic
## Testing and Validation

# Phase Three: Data Visualisation
## Overview of phase three
## Dashboard Design and Implementation

# Lessons Learned

- **Data quality isn't automatic - even for public datasets.**  
  I expected some cleaning... but not *this much*. Building in quality checks early paid off massively.

- **Delete with caution.**  
  Instead of blindly deleting bad records, keeping a separate invalids table gave me peace of mind - and documentation if anyone ever asked, *"What happened to X?"*

- **Understand before modeling.**  
  Querying in Athena first helped me spot potential pitfalls before getting deep into dbt modeling. A few hours of extra care here saved days later.

- **Focus on what matters.**  
  Not every field deserved equal attention. Picking my battles based on business value made the project manageable and more meaningful.
  
