# Olist E-Commerce Data Warehouse 📦🇧🇷

![Cover Image](pic/Cover%20Page.png)

**Author:** Abdallah Ali Abdelgawad


## 📌 Project Overview
This project involves the end-to-end design and implementation of an enterprise-grade Data Warehouse for **Olist**, a major Brazilian e-commerce marketplace enabler[cite: 13, 17]. The primary objective is to transform highly normalized, disparate operational datasets into a centralized, performant analytical source of truth to empower business intelligence and strategic decision-making[cite: 17].

## 🏗️ Architecture & ETL Pipeline
The data engineering pipeline was built using **Microsoft SQL Server (T-SQL)** and structured following the **Medallion Architecture** to ensure data quality and auditability[cite: 17]:

1. **Bronze Layer (Raw):** Bulk ingestion of 11 raw CSV files (Marketing Funnel & E-Commerce Datasets) into staging tables, preserving historical raw data[cite: 17].
2. **Silver Layer (Cleansed):** Data cleansing, type casting, string normalization, and handling missing values. A custom UDF (`Fn_Correct_Known_City`) was implemented to resolve complex geographical typos[cite: 17].
3. **Gold Layer (Business Model):** Data modeled into a Star Schema optimized for OLAP analytical queries, utilizing `MERGE` statements for Upserts[cite: 17].

## 🗄️ Data Modeling (Star Schema)
The Gold Layer is designed as a **Star Schema** to eliminate complex 6+ table joins found in the source OLTP system, significantly boosting BI performance[cite: 17].

![Gold Star Schema ERD](pic/Gold%20Layer%20Star%20Schema.png)

* **Fact Tables:** `Fact_Orders`, `Fact_Order_Items`, `Fact_Payments`, `Fact_Reviews`, `Fact_Marketing_Funnel`[cite: 17].
* **Dimension Tables:** `Dim_Customer`, `Dim_Seller`, `Dim_Product`, `Dim_Date`[cite: 17].

### ⚙️ Advanced Modeling Techniques
* **Surrogate Keys & Unknown Members:** Implemented IDENTITY columns for dimensions and injected default `-1` rows to gracefully handle early-arriving facts without breaking referential integrity[cite: 17].
* **Slowly Changing Dimensions (SCD Type 2):** Applied to `Dim_Customer` and `Dim_Seller` to track geographical relocations over time, ensuring historical orders report accurate freight and routing logic[cite: 17].

## 🚀 Performance & Scalability
To handle massive data volumes and ensure lightning-fast analytical queries, the following physical database tuning techniques were applied[cite: 17]:
* **Table Partitioning:** Fact tables (`Fact_Orders`, `Fact_Order_Items`) are physically partitioned across the disk by `Purchase_Date_Key` (yearly ranges: 2017, 2018, 2019+), enabling partition elimination during time-series queries[cite: 17].
* **Columnstore Indexing:** Applied Nonclustered Columnstore Indexes (NCCI) to Fact tables, drastically reducing I/O for heavy `SUM` and `AVG` aggregations in the BI layer[cite: 17].

## 📊 Analytical Reporting & BI
The project culminates in a comprehensive **Power BI** dashboard built directly on top of the Gold Star Schema, addressing core business questions[cite: 17].

![Power BI Dashboard](pic/PowerBi_DashBoard.png)

### 💡 Key Insights:
* **Platform Scale:** Successfully processed 98K total orders, generating a total revenue of 13M with an Average Order Value (AOV) of $137.41[cite: 17].
* **Revenue Trend:** Demonstrated massive scale-up, skyrocketing to 5.6M in 2017 and 7.6M by 2018[cite: 17].
* **Top Categories:** 'Health & Beauty' (1.3M) and 'Watches & Gifts' (1.2M) drive the highest financial value[cite: 17].
* **Payment Preferences:** Brazilian consumers heavily favor Credit Cards (78.34%), with Boleto (bank slips) as the secondary method (17.92%)[cite: 17].

## 📁 Source Systems & Data Origin
The source data consists of 11 highly normalized flat files from Kaggle, representing Olist's CRM (Marketing Funnel) and ERP (Orders, Payments, Products, Reviews) systems[cite: 17]. 

![OLTP Database Design](pic/OLTP%20Database%20Design.png)
