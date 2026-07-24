Use Olist_e_Commerce;
Go

-- =================================================================
-- 0. Safe Drop Order (Facts then Dims) to avoid FK Constraint errors
-- =================================================================
If Object_Id('Gold.Fact_Marketing_Funnel','U') Is Not Null Drop Table Gold.Fact_Marketing_Funnel;
If Object_Id('Gold.Fact_Reviews','U') Is Not Null Drop Table Gold.Fact_Reviews;
If Object_Id('Gold.Fact_Payments','U') Is Not Null Drop Table Gold.Fact_Payments;
If Object_Id('Gold.Fact_Order_Items','U') Is Not Null Drop Table Gold.Fact_Order_Items;
If Object_Id('Gold.Fact_Orders','U') Is Not Null Drop Table Gold.Fact_Orders;

If Object_Id('Gold.Dim_Customer','U') Is Not Null Drop Table Gold.Dim_Customer;
If Object_Id('Gold.Dim_Seller','U') Is Not Null Drop Table Gold.Dim_Seller;
If Object_Id('Gold.Dim_Product','U') Is Not Null Drop Table Gold.Dim_Product;
If Object_Id('Gold.Dim_Date','U') Is Not Null Drop Table Gold.Dim_Date;

-- =================================================================
-- 1. Partitioning Setup (Function & Scheme)
-- =================================================================
If Exists (Select 1 From sys.partition_schemes Where name = 'PS_Fact_Date')
	Drop Partition Scheme PS_Fact_Date;
Go
If Exists (Select 1 From sys.partition_functions Where name = 'PF_Fact_Date')
	Drop Partition Function PF_Fact_Date;
Go

Create Partition Function PF_Fact_Date (Int)
As Range Right For Values (20170101, 20180101, 20190101);
Go

Create Partition Scheme PS_Fact_Date
As Partition PF_Fact_Date All To ([PRIMARY]);
Go

-- =================================================================
-- 2. Dimensions
-- =================================================================
Create Table Gold.Dim_Date(
	Date_Key       Int         Not Null,   -- Format: YYYYMMDD, e.g. 20180315
	Full_Date      Date        Not Null,
	Year_Number    Int         Not Null,
	Quarter_Number Int         Not Null,
	Month_Number   Int         Not Null,
	Month_Name     Nvarchar(20) Not Null,
	Day_Name       Nvarchar(20) Not Null,
	Is_Weekend     Bit         Not Null,
	Constraint PK_Dim_Date Primary Key (Date_Key)
);
Go

Create Table Gold.Dim_Product(
	Product_Key    Int Identity(1,1) Not Null,
	product_id     Nvarchar(50) Not Null,
	Category_Name_Pt Nvarchar(200),
	Category_Name_En Nvarchar(200),
	product_name_length Int,
	product_description_length Int,
	product_photos_qty Int,
	product_weight_g Int,
	product_length_cm Int,
	product_height_cm Int,
	product_width_cm Int,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Dim_Product Primary Key (Product_Key),
	Constraint UQ_Dim_Product_BusinessKey Unique (product_id)
);
Go

Set Identity_Insert Gold.Dim_Product On;
Insert Into Gold.Dim_Product (Product_Key, product_id, Category_Name_Pt, Category_Name_En)
Values (-1, 'UNKNOWN', 'Unknown', 'Unknown');
Set Identity_Insert Gold.Dim_Product Off;
Go

Create Table Gold.Dim_Seller(
	Seller_Key      Int Identity(1,1) Not Null,
	seller_id       Nvarchar(50) Not Null,
	seller_zip_code_prefix Nvarchar(20),
	seller_city     Nvarchar(100),
	seller_state    Nvarchar(10),
	geolocation_lat Numeric(18,10),
	geolocation_lng Numeric(18,10),
	Effective_Start_Date Datetime2 Not Null Default Sysdatetime(),
	Effective_End_Date   Datetime2 Null,
	Is_Current      Bit Not Null Default 1,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Dim_Seller Primary Key (Seller_Key)
);
Go

Set Identity_Insert Gold.Dim_Seller On;
Insert Into Gold.Dim_Seller (Seller_Key, seller_id, seller_city, seller_state, Effective_Start_Date, Is_Current)
Values (-1, 'UNKNOWN', 'Unknown', 'NA', Sysdatetime(), 1);
Set Identity_Insert Gold.Dim_Seller Off;
Go

Create Table Gold.Dim_Customer(
	Customer_Key    Int Identity(1,1) Not Null,
	customer_unique_id Nvarchar(50) Not Null,
	customer_zip_code_prefix Nvarchar(20),
	customer_city   Nvarchar(100),
	customer_state  Nvarchar(10),
	geolocation_lat Numeric(18,10),
	geolocation_lng Numeric(18,10),
	Effective_Start_Date Datetime2 Not Null Default Sysdatetime(),
	Effective_End_Date   Datetime2 Null,
	Is_Current      Bit Not Null Default 1,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Dim_Customer Primary Key (Customer_Key)
);
Go

Set Identity_Insert Gold.Dim_Customer On;
Insert Into Gold.Dim_Customer (Customer_Key, customer_unique_id, customer_city, customer_state, Effective_Start_Date, Is_Current)
Values (-1, 'UNKNOWN', 'Unknown', 'NA', Sysdatetime(), 1);
Set Identity_Insert Gold.Dim_Customer Off;
Go

-- =================================================================
-- 3. Facts
-- =================================================================
Create Table Gold.Fact_Orders(
	order_id        Nvarchar(50) Not Null,
	Customer_Key    Int Not Null,
	Purchase_Date_Key Int Not Null,
	Delivered_Date_Key Int Null,
	Estimated_Delivery_Date_Key Int Null,
	order_status    Nvarchar(50),
	Is_Revenue_Eligible Bit Not Null,
	order_approved_at Datetime,
	order_delivered_carrier_date Datetime,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	
	Constraint PK_Fact_Orders Primary Key Nonclustered (order_id) On [PRIMARY],
	Constraint FK_Fact_Orders_Customer Foreign Key (Customer_Key) References Gold.Dim_Customer(Customer_Key),
	Constraint FK_Fact_Orders_PurchaseDate Foreign Key (Purchase_Date_Key) References Gold.Dim_Date(Date_Key),
	Constraint FK_Fact_Orders_DeliveredDate Foreign Key (Delivered_Date_Key) References Gold.Dim_Date(Date_Key),
	Constraint FK_Fact_Orders_EstDeliveryDate Foreign Key (Estimated_Delivery_Date_Key) References Gold.Dim_Date(Date_Key)
);
Go
Create Clustered Index CIX_Fact_Orders On Gold.Fact_Orders(Purchase_Date_Key) On PS_Fact_Date(Purchase_Date_Key);
Go


Create Table Gold.Fact_Order_Items(
	order_id        Nvarchar(50) Not Null,
	order_item_number Int Not Null,
	Product_Key     Int Not Null,
	Seller_Key      Int Not Null,
	Purchase_Date_Key Int Not Null,
	price           Decimal(12,2),
	freight_value   Decimal(12,2),
	Is_Revenue_Eligible Bit Not Null,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	
	Constraint PK_Fact_Order_Items Primary Key Nonclustered (order_id, order_item_number) On [PRIMARY],
	Constraint FK_Fact_Order_Items_Order Foreign Key (order_id) References Gold.Fact_Orders(order_id),
	Constraint FK_Fact_Order_Items_Product Foreign Key (Product_Key) References Gold.Dim_Product(Product_Key),
	Constraint FK_Fact_Order_Items_Seller Foreign Key (Seller_Key) References Gold.Dim_Seller(Seller_Key)
);
Go
Create Clustered Index CIX_Fact_Order_Items On Gold.Fact_Order_Items(Purchase_Date_Key) On PS_Fact_Date(Purchase_Date_Key);
Go


Create Table Gold.Fact_Payments(
	order_id        Nvarchar(50) Not Null,
	payment_sequential Int Not Null,
	payment_type    Nvarchar(50),
	payment_installments Int,
	payment_value   Decimal(12,2),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Fact_Payments Primary Key (order_id, payment_sequential),
	Constraint FK_Fact_Payments_Order Foreign Key (order_id) References Gold.Fact_Orders(order_id)
);
Go


Create Table Gold.Fact_Reviews(
	review_id       Nvarchar(50) Not Null,
	order_id        Nvarchar(50) Not Null,
	review_score    Int,
	review_comment_title Nvarchar(Max),
	review_comment_message Nvarchar(Max),
	Review_Creation_Date_Key Int Not Null,
	review_answer_timestamp Datetime2,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Fact_Reviews Primary Key (review_id, order_id),
	Constraint FK_Fact_Reviews_Order Foreign Key (order_id) References Gold.Fact_Orders(order_id),
	Constraint FK_Fact_Reviews_CreationDate Foreign Key (Review_Creation_Date_Key) References Gold.Dim_Date(Date_Key)
);
Go


Create Table Gold.Fact_Marketing_Funnel(
	mql_id          Nvarchar(50) Not Null,
	Seller_Key      Int Not Null,
	First_Contact_Date_Key Int Not Null,
	Won_Date_Key    Int Null,
	landing_page_id Nvarchar(50),
	origin          Nvarchar(50),
	sdr_id          Nvarchar(50),
	sr_id           Nvarchar(50),
	business_segment Nvarchar(100),
	lead_type       Nvarchar(100),
	lead_behaviour_profile Nvarchar(100),
	has_company     Bit,
	has_gtin        Bit,
	average_stock   Nvarchar(50),
	business_type   Nvarchar(50),
	declared_product_catalog_size Int,
	declared_monthly_revenue Int,
	Is_Converted    Bit Not Null,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Fact_Marketing_Funnel Primary Key (mql_id),
	Constraint FK_Fact_Marketing_Funnel_Seller Foreign Key (Seller_Key) References Gold.Dim_Seller(Seller_Key),
	Constraint FK_Fact_Marketing_Funnel_FirstContact Foreign Key (First_Contact_Date_Key) References Gold.Dim_Date(Date_Key),
	Constraint FK_Fact_Marketing_Funnel_WonDate Foreign Key (Won_Date_Key) References Gold.Dim_Date(Date_Key)
);
Go

-- =================================================================
-- 4. Analytical Indexing (Performance Boost)
-- =================================================================

-- Columnstore Indexes (Best for Data Warehousing Aggregations)
Create Nonclustered Columnstore Index NCCI_Fact_Orders 
On Gold.Fact_Orders (Customer_Key, Purchase_Date_Key, order_status, Is_Revenue_Eligible)
On PS_Fact_Date(Purchase_Date_Key);
Go

Create Nonclustered Columnstore Index NCCI_Fact_Order_Items 
On Gold.Fact_Order_Items (Product_Key, Seller_Key, Purchase_Date_Key, price, freight_value)
On PS_Fact_Date(Purchase_Date_Key);
Go

-- B-Tree Indexes (Best for Joins and Filtering)
Create Nonclustered Index IX_Fact_Orders_Customer 
On Gold.Fact_Orders(Customer_Key) Include (order_status);
Go

Create Nonclustered Index IX_Fact_Order_Items_Product 
On Gold.Fact_Order_Items(Product_Key) Include (price, freight_value);
Go

Create Nonclustered Index IX_Fact_Order_Items_Seller 
On Gold.Fact_Order_Items(Seller_Key) Include (price, freight_value);
Go