Use Olist_e_Commerce;
Go

/*
============================
	Creating CRM Tables
============================
*/

If Object_Id('Silver.Crm_closed_deals','U') Is Not Null
	Drop Table Silver.Crm_closed_deals;

Create Table Silver.Crm_closed_deals(
	mql_id Nvarchar(50) Not Null,
	seller_id Nvarchar(50) Not Null,
	sdr_id Nvarchar(50),
	sr_id Nvarchar(50),
	won_date Datetime,
	business_segment Nvarchar(100),
	lead_type Nvarchar(100),
	lead_behaviour_profile Nvarchar(100),
	has_company Bit,
	has_gtin Bit,
	average_stock Nvarchar(50),
	business_type Nvarchar(50),
	declared_product_catalog_size Int,
	declared_monthly_revenue Int,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Crm_closed_deals Primary Key (mql_id)
);
Go

If Object_Id('Silver.Crm_customers','U') Is Not Null
	Drop Table Silver.Crm_customers;

Create Table Silver.Crm_customers(
	customer_id Nvarchar(50) Not Null,
	customer_unique_id Nvarchar(50) Not Null,
	customer_zip_code_prefix Nvarchar(20),
	customer_city Nvarchar(100),
	customer_state Nvarchar(10),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Crm_customers Primary Key (customer_id)
);
Go

If Object_Id('Silver.Crm_marketing_qualified_leads','U') Is Not Null
	Drop Table Silver.Crm_marketing_qualified_leads;

Create Table Silver.Crm_marketing_qualified_leads(
	mql_id Nvarchar(50) Not Null,
	first_contact_date Datetime,
	landing_page_id Nvarchar(50),
	origin Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Crm_marketing_qualified_leads Primary Key (mql_id)
);
Go

-- Composite PK: review_id alone is not reliably unique in the source —
-- Olist reuses the same review_id across different orders when review
-- content is identical. (review_id, order_id) together is confirmed unique.
If Object_Id('Silver.Crm_order_reviews','U') Is Not Null
	Drop Table Silver.Crm_order_reviews;

Create Table Silver.Crm_order_reviews(
	review_id Nvarchar(50) Not Null,
	order_id Nvarchar(50) Not Null,
	review_score Int,
	review_comment_title Nvarchar(Max),
	review_comment_message Nvarchar(Max),
	review_creation_date Datetime2,
	review_answer_timestamp Datetime2,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Crm_order_reviews Primary Key (review_id, order_id)
);
Go

/*
============================
	Creating ERP Tables
============================
*/

If Object_Id('Silver.Erp_orders','U') Is Not Null
	Drop Table Silver.Erp_orders;

Create Table Silver.Erp_orders(
	order_id Nvarchar(50) Not Null,
	customer_id Nvarchar(50) Not Null,
	order_status Nvarchar(50),
	order_purchase_timestamp Datetime,
	order_approved_at Datetime,
	order_delivered_carrier_date Datetime,
	order_delivered_customer_date Datetime,
	order_estimated_delivery_date Datetime,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Erp_orders Primary Key (order_id),
	Constraint FK_Erp_orders_Customer Foreign Key (customer_id) References Silver.Crm_customers(customer_id)
);
Go

If Object_Id('Silver.Erp_products','U') Is Not Null
	Drop Table Silver.Erp_products;

Create Table Silver.Erp_products(
	product_id Nvarchar(50) Not Null,
	product_category_name Nvarchar(100),
	product_name_length Int,
	product_description_length Int,
	product_photos_qty Int,
	product_weight_g Int,
	product_length_cm Int,
	product_height_cm Int,
	product_width_cm Int,
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Erp_products Primary Key (product_id)
);
Go

If Object_Id('Silver.Erp_sellers','U') Is Not Null
	Drop Table Silver.Erp_sellers;

Create Table Silver.Erp_sellers(
	seller_id Nvarchar(50) Not Null,
	seller_zip_code_prefix Nvarchar(20),
	seller_city Nvarchar(100),
	seller_state Nvarchar(10),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Erp_sellers Primary Key (seller_id)
);
Go

-- Composite natural key: order_item_number alone repeats across orders
-- (it's the item's position within one order, not globally unique).
-- Surrogate key intentionally deferred to Gold, not introduced here.
If Object_Id('Silver.Erp_order_items','U') Is Not Null
	Drop Table Silver.Erp_order_items;

Create Table Silver.Erp_order_items(
	order_id Nvarchar(50) Not Null,
	order_item_number Int Not Null,
	product_id Nvarchar(50) Not Null,
	seller_id Nvarchar(50) Not Null,
	shipping_limit_date Datetime,
	price Decimal(12,2),
	freight_value Decimal(12,2),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Erp_order_items Primary Key (order_id, order_item_number),
	Constraint FK_Erp_order_items_Order Foreign Key (order_id) References Silver.Erp_orders(order_id),
	Constraint FK_Erp_order_items_Product Foreign Key (product_id) References Silver.Erp_products(product_id),
	Constraint FK_Erp_order_items_Seller Foreign Key (seller_id) References Silver.Erp_sellers(seller_id)
);
Go

If Object_Id('Silver.Erp_order_payments','U') Is Not Null
	Drop Table Silver.Erp_order_payments;

Create Table Silver.Erp_order_payments(
	order_id Nvarchar(50) Not Null,
	payment_sequential Int Not Null,
	payment_type Nvarchar(50),
	payment_installments Int,
	payment_value Decimal(12,2),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Erp_order_payments Primary Key (order_id, payment_sequential),
	Constraint FK_Erp_order_payments_Order Foreign Key (order_id) References Silver.Erp_orders(order_id)
);
Go

If Object_Id('Silver.Erp_product_category_name_translation','U') Is Not Null
	Drop Table Silver.Erp_product_category_name_translation;

Create Table Silver.Erp_product_category_name_translation(
	product_category_name Nvarchar(200) Not Null,
	product_category_name_english Nvarchar(200),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime(),
	Constraint PK_Erp_category_translation Primary Key (product_category_name)
);
Go

-- Reference/lookup data — no reliable single or composite key, no PK enforced.
If Object_Id('Silver.Erp_geolocation','U') Is Not Null
	Drop Table Silver.Erp_geolocation;

Create Table Silver.Erp_geolocation(
	geolocation_zip_code_prefix Nvarchar(20),
	geolocation_lat Numeric(18,10),
	geolocation_lng Numeric(18,10),
	geolocation_city Nvarchar(100),
	geolocation_state Nvarchar(10),
	Batch_Id Uniqueidentifier Null,
	load_date_timestamp Datetime2 Default Sysdatetime()
);
Go