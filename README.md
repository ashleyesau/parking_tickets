

# End-to-end Data Engineering Pipeline using NYC Parking Ticket Data


**This project is my "before" picture**—the messy first draft of my data engineering journey. Would people judge the code? Was it "good enough"? But then it occurred to me—**every expert started somewhere**, and this project is my "somewhere."

I started with **a mountain of messy data** and a stubborn belief that I could wrangle it into something useful. Along the way:

- **I broke things** (then learned how AWS Redshift _really_ works)  
- **I nearly quit** when tools refused to talk to each other (_who knew configuration could be such a battleground?_)  
- **I celebrated small wins** (like my first clean dbt transformation)  
- **I discovered** that good engineering isn't about perfect code—**it's about solving problems step by frustrating step**  

**This project isn't perfect** (what first try is?), but it's _real_—a snapshot of me growing as an aspiring data engineer.  

**Thanks for being here! Let's dive in!**


## Table of Contents

- [What This Project Is Really About](#what-this-project-is-really-about)
- [Tech Stack](#tech-stack)
- [NYC Parking Tickets Dataset Overview](#nyc-parking-tickets-dataset-overview)
- [Key Analysis Questions](#key-analysis-questions)
  - [Violation Patterns](#violation-patterns)
  - [Vehicle Insights](#vehicle-insights)
  - [Enforcement Trends](#enforcement-trends)
- [Phase One: Data Ingestion, Quality Checks, and Cleaning](#phase-one-data-ingestion-quality-checks-and-cleaning)
  - [Overview of phase one](#overview-of-phase-one)
  - [Steps and Processes](#steps-and-processes)
    - [Load Raw Data into Amazon S3](#load-raw-data-into-amazon-s3)
    - [Infer Schema Using AWS Glue Crawler](#infer-schema-using-aws-glue-crawler)
    - [Exploring and Validating Data Quality in Athena](#exploring-and-validating-data-quality-in-athena)
    - [How I Checked the Data](#how-i-checked-the-data)
    - [Handling Invalid Records](#handling-invalid-records)
- [Phase Two: Data Modeling with dbt](#phase-two-data-modeling-with-dbt)
  - [Overview of phase two](#overview-of-phase-two)
  - [Workflow](#workflow)
  - [Objectives](#objectives)
- [Schema Design and Implementation](#schema-design-and-implementation)
- [Transformation Logic](#transformation-logic)
- [Testing and Validation](#testing-and-validation)
- [Lessons Learned](#lessons-learned)
- [Future phases](#future-phases)




##  What This Project Is Really About

I wanted to **build something real**—not just follow a tutorial. With **42 million messy NYC parking tickets** as my raw material, I set out to:

- **Ask better questions**  
  *(What stories does this data tell? How should the pipeline answer them?)*  
- **Build something that wouldn't break**  
  `AWS (S3 → Glue → Redshift)` + `dbt` = a pipeline that actually scales  
- **Clean up the chaos**  
  Public data is messy—I learned to **validate**, **transform**, and make it usable  
- **Make analytics fast**  
  Because nobody likes waiting hours for a query to finish  
- **Level up my skills**  
  This was my playground for **cloud engineering** and **thoughtful pipeline design**  

**At its core?** Turning overwhelming data into something clear and useful—one stubborn problem at a time.

# Tech Stack

| Tool           | Purpose                                  |
|----------------|------------------------------------------|
| AWS S3         | Raw & cleaned data storage               |
| AWS Glue       | Schema inference, ETL with PySpark       |
| AWS Athena     | Query raw data for validation            |
| AWS Redshift   | Cloud data warehouse                     |
| dbt (Data Build Tool) | Data modeling and testing                |
| GitHub         | Version control for dbt models and project code |



## Tech Overview

This section provides a quick overview of the tools used in this project.

### **Amazon S3 (Simple Storage Service)**
Amazon S3 is a cloud-based storage service that allows you to store any type of file — from raw data to images, videos, and backups. In this project, I use S3 as the **data lake**, where I land raw data and store intermediate and final outputs.

> **Think of it like:** A massive online hard drive or file cabinet that you can organize and access using code.

---

### **AWS Glue**
AWS Glue is a serverless data integration tool that enables you to run ETL (Extract, Transform, Load) jobs using Apache Spark without the need to manage infrastructure.

> **Think of it like:** A programmable data janitor that transforms messy raw data into clean, usable formats.

---

### **AWS Athena**
Amazon Athena is a query service that allows you to run SQL queries directly on data stored in S3 — no need to load it into a database. It integrates with the AWS Glue Data Catalog to understand the structure of the data.

> **Think of it like:** A magnifying glass that lets you search through your files in S3 using simple SQL.

---

### **Amazon Redshift**
Amazon Redshift is a fully managed data warehouse that enables you to run complex queries on large datasets quickly. It stores structured data for analysis and is designed for high-performance querying across large datasets.

> **Think of it like:** A super-powered database built to handle and analyze massive amounts of data.

---

### **dbt (Data Build Tool)**
dbt is an open-source tool that helps transform raw data inside your warehouse. It allows data engineers to write, test, and maintain SQL queries that convert raw data into analytics-ready tables. In this project, I connect dbt to AWS Redshift.

> **Think of it like:** A tool that helps clean and organize your data, making it easier for analysts to work with.

---

### **Git & GitHub**
Git is a version control system that tracks changes in your code. GitHub is an online platform where you can store, share, and collaborate on code. The source code for this project lives on GitHub.

> **Think of it like:** Google Docs for code — you can save versions, collaborate, and track every change.





# NYC Parking Tickets Dataset Overview

**42 million records** of NYC parking violations containing:
- Over **50 data fields** capturing violation details
- **Key attributes** like:
  - `violation type` 
  - `location data`
  - `vehicle make`
  - `issue date/time`
- **Rich potential** for analyzing parking behavior and enforcement trends

# Key Analysis Questions

### Violation Patterns
- **What types are most common?**  
  *(Breakdown by violation code/description)*
- **Where do they cluster?**  
  *(By county, precinct & street name)*
- **When do they occur?**  
  *(Time patterns in issue dates/times)*

### Vehicle Insights
- **Which car brands get ticketed most?**  
  *(Analysis by vehicle make)*
- **Special violation types**  
  *(Frequency of hydrant/double parking violations)*

### Enforcement Trends
- **Who's issuing tickets?**  
  *(By agency, squad & precinct)*
   
    

# Phase One: Data Ingestion, Quality Checks, and Cleaning  
## Overview of Phase One  

In this first phase, I focused on building a **strong foundation** for the project by carefully **bringing in, checking, and cleaning** the raw NYC parking ticket data.

The dataset started big — about **42 million records** from four years (**2014 to 2017**). I loaded the raw CSV files into **Amazon S3**, where they served as the starting point for the pipeline. Using **AWS Glue**, I automatically scanned the files to **infer the schema** and organized everything into a **central, searchable database**.

To catch issues early, I ran SQL queries using **AWS Athena**. This helped me **quickly uncover problems** in the data — like missing values or strange formatting — so I could **clean things up before moving on**.

This phase was all about **laying the groundwork for scale**:  
- **Making sense of messy, real-world data**  
- **Catching quality issues before they snowball**  
- **Setting up a clean and reliable base** for everything that comes next  


## Steps and Processes

### **Load Raw Data into Amazon S3**

- Downloaded the raw NYC parking tickets dataset in **CSV format** from Kaggle.  
- Loaded four CSV files into an **Amazon S3 bucket**, covering **2014–2017**.  
- Each year’s file contained roughly **10 million rows**, adding up to around **42 million records** in total.

Kaggle view of the dataset:  
[![Screenshot-2025-04-26-at-08-22-03.png](https://i.postimg.cc/wMPt2Bkn/Screenshot-2025-04-26-at-08-22-03.png)](https://postimg.cc/2LQ88rMx)

S3 bucket structure:  
[![Screenshot-2025-04-26-at-08-29-43.png](https://i.postimg.cc/hhWDhQs4/Screenshot-2025-04-26-at-08-29-43.png)](https://postimg.cc/K3fSHzCC)

---

### **Infer Schema Using AWS Glue Crawler**

- Set up an **AWS Glue Crawler** to scan all four files and **automatically infer the schema**.  
- Configured the crawler to:
  - **Combine** all files into a **single table** (they all share the same structure).  
  - Store the inferred schema in a **new Glue database** for easier querying.

Crawler setup view:  
[![Screenshot-2025-04-26-at-09-21-39.png](https://i.postimg.cc/QVGfPj8n/Screenshot-2025-04-26-at-09-21-39.png)](https://postimg.cc/zH7wHZRn)

Resulting Glue database:  
[![Screenshot-2025-04-26-at-09-25-29.png](https://i.postimg.cc/L41KyXvD/Screenshot-2025-04-26-at-09-25-29.png)](https://postimg.cc/dDwx3JbZ)

---

### **Exploring and Validating Data Quality in Athena**

With the table set up in Glue, I jumped into **AWS Athena** to do some hands-on exploration and validation.

The dataset had over **50 columns**, but I focused on the **16 core fields** that mattered most for insights and future transformations:

| #  | Column                   | Purpose                       |
|----|--------------------------|-------------------------------|
| 1  | `summons_number`         | Unique ticket identifier      |
| 2  | `issue_date`             | Time-based analysis           |
| 3  | `plate_id`               | Vehicle identification        |
| 4  | `plate_type`             | Vehicle classification        |
| 5  | `violation_code`         | Numeric violation type        |
| 6  | `violation_description`  | Human-readable violation      |
| 7  | `violation_county`       | Regional grouping             |
| 8  | `violation_precinct`     | Localized area grouping       |
| 9  | `street_name`            | Location-based analysis       |
| 10 | `registration_state`     | Vehicle origin analysis       |
| 11 | `vehicle_body_type`      | Vehicle category analysis     |
| 12 | `vehicle_make`           | Brand analysis                |
| 13 | `vehicle_year`           | Age analysis                  |
| 14 | `issuing_agency`         | Agency-level analysis         |
| 15 | `issuer_squad`           | Squad-level patterns          |
| 16 | `issuer_precinct`        | Ties squad to geography       |

---

### **How I Checked the Data**

I didn’t just want data that was *present* — I wanted it to be **reliable**. So I designed a few key quality checks:

- **Are the critical fields filled in?**  
  Checked that important columns like `summons_number`, `issue_date`, and `violation_code` weren't missing.

- **Where are the gaps?**  
  Looked for `NULL`s and blanks to understand which fields might be unreliable.

- **Is the data usable?**  
  Ensured dates could be parsed, times were in consistent formats, and weird values wouldn’t break downstream processes.

- **Did Glue guess the schema correctly?**  
  Cross-checked data types — found a few surprises, like numbers stored as strings.

- **Any duplicate tickets?**  
  `summons_number` should be unique — duplicates could mess up future aggregations.

- **Anything that just looks off?**  
  I flagged records with:
  - Negative distances in `feet_from_curb`
  - Strange `violation_times`
  - Typos or odd entries in `vehicle_make`

---

### **Handling Invalid Records**

Instead of quietly dropping bad data, I made a point to **track it transparently**:

- Created a **separate table** to hold invalid or suspicious records.  
- Logged **every dropped row** along with:
  - The full original record  
  - The **reason** it was flagged (e.g. missing key field, malformed date, duplicate ID)  

This way, the cleaned dataset stays solid, but the messy bits aren’t lost — they’re just **set aside for review or audit later**.




-----------

# Phase Two: Data Modeling with dbt

## Overview of Phase Two

In this phase of the project, the focus shifts to transforming and structuring the cleaned data using **dbt (data build tool)** to prepare it for analysis and reporting. This builds on the work done in Phase One (data ingestion and cleaning with AWS Glue and Athena).

The goal here is to make the raw parking ticket data easier to work with — more organized, trustworthy, and analytics-ready.

---

## Workflow

Here’s what I did during this phase:

- Connected **dbt** to **Amazon Redshift** (our cloud data warehouse)
- Created a series of **dbt models** (SQL files) to define clear transformation steps
- Wrote **modular, testable SQL code** that’s easy to reuse and maintain
- Ran and tested the models locally and in the cloud
- Documented each model and generated a browsable **dbt docs site**

---

## Objectives

The modeling phase was designed to:

- Structure the raw data into **clean, analysis-ready datasets**
- Apply **data quality checks** to ensure consistency and accuracy
- Build trust in the data by using **version control**, testing, and clear documentation

---

## Schema Design and Implementation

I used a **star schema** approach to organize the data. At the center is a **fact table** with the core parking ticket data, and surrounding it are several **dimension tables** that provide additional context like vehicle details, violation types, and time information.

>  **What’s a Star Schema?**  
> A star schema is a way of organizing data for analysis.  
> Think of it like a hub-and-spoke model:  
> - At the center is a **fact table** with the main events (like parking tickets).  
> - Around it are **dimension tables** with extra details (like vehicle info, officer info, time, and location).  
> This setup makes it faster and easier to run reports, answer business questions, and spot patterns in the data.


This design makes it easier to query and analyze the data — whether you're slicing by vehicle make, filtering by precinct, or spotting patterns over time.

Here’s a look at how the data is structured:

[![Schema Diagram](https://i.postimg.cc/YSt9GxfR/Screenshot-2025-05-05-at-11-59-42.png)](https://postimg.cc/fVgZ1mPS)

---

## Modeled Tables

The final dbt models include:

- A central **fact table**: `parking_tickets_fact`
- Supporting **dimension tables**:
  - `dim_vehicle`
  - `dim_violation`
  - `dim_officer`
  - `dim_date`

Each table plays a specific role in enriching the core ticket data with relevant details — making it easier to explore trends, run reports, and extract insights.

---

## Transformation Logic

Each dbt model defines a specific step in the data cleaning and enrichment process. For example:

- Standardizing date formats and aligning time zones
- Deduplicating records where necessary
- Mapping vehicle codes to readable names
- Creating unique IDs for dimensions like vehicle and officer
- Simplifying column names for easier querying

The transformations follow clear naming conventions and are grouped logically in folders — so it’s easy to trace where any piece of data came from and how it was shaped.

---

## Testing and Validation

To make sure the models were solid and trustworthy, I added built-in tests using dbt. These include:

- **Uniqueness tests** (e.g., no duplicate `summons_number` in the fact table)
- **Not null checks** on critical fields
- **Relationship tests** to ensure foreign keys (like `plate_id`) match between fact and dimension tables

These checks catch issues early, so bad data doesn’t silently sneak into reports or dashboards.

---




## Lessons Learned

### **Tool Configuration Can Be the Hardest Part**
One of the most frustrating parts of this project was getting various AWS services to communicate with each other—especially configuring **IAM roles, policies,** and **permissions**. Connecting **dbt** to **Redshift** also took a lot of trial and error. I **underestimated** how much time and patience would be required just to set up the tools and make sure they all worked together. It wasn’t glamorous work, but it reinforced how **critical** infrastructure setup is in real-world data engineering.

### **Documentation Is Never Enough**
I learned that the official documentation wasn’t always enough. I often turned to forums, **GitHub issues,** and community posts when I got stuck. Often, the problem wasn’t that I didn’t understand the tools—it was that they were **picky** about versions, settings, or connection protocols.

### **Smooth Is Fast**
Rushing through configuration to “get to the real work” usually slowed me down even more. Taking a **methodical** approach—reading logs carefully and testing small pieces at a time—actually helped me move faster in the long run.

### **Pushing Through the Mess**
There was a point during the **Athena** data validation stage where I almost gave up—the dataset felt too **messy** to be useful. But after taking a break, I reminded myself that turning messy data into something usable *is* the job. That shift in mindset helped me push through and recommit to building a functional **dbt** model. I also learned that **data quality** isn’t automatic—even with public datasets. I expected some cleaning, but not as much as I encountered. Fortunately, having **quality checks** in place early on made it easier to catch issues and stay on track.

### **Delete with Caution**
Rather than blindly deleting bad records, keeping a separate **`invalids` table** gave me peace of mind—and **documentation** in case anyone ever asked, "_What happened to X?_"

### **Understand Before Modeling**
Spending time querying the data in **Athena** helped me identify potential pitfalls before diving deep into **dbt modeling**. A few hours of extra care here saved me **days** of rework later.

### **Focus on What Matters**
Not every field deserved equal attention. I focused on the data that had the most **business value**, making the project more **manageable** and **meaningful**.


 
# Future Phases

This project is a work in progress, and I plan to return to it in future iterations. Upcoming phases will focus on:

- **Data Visualization**: Building interactive dashboards and visual summaries to explore trends in NYC parking violations.
- **Automation with Airflow**: Orchestrating the pipeline using Apache Airflow to schedule, monitor, and automate the data workflows end-to-end.

These enhancements will help bring the insights to life and make the project more scalable, reliable, and production-ready.
