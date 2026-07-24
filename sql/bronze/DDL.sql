Use Olist_e_Commerce;
Go

If Object_Id('Bronze.Crm_closed_deals','U') Is Not Null
	Drop Table Bronze.Crm_closed_deals;

Create Table Bronze.Crm_closed_deals(
	mql_id Nvarchar(50),
	seller_id Nvarchar(50),
	sdr_id Nvarchar(50),
	sr_id Nvarchar(50),
	won_date Nvarchar(50),
	business_segment Nvarchar(100),
	lead_type Nvarchar(100),
	lead_behaviour_profile Nvarchar(100),
	has_company Nvarchar(10),
	has_gtin Nvarchar(10),
	average_stock Nvarchar(50),
	business_type Nvarchar(50),
	declared_product_catalog_size Nvarchar(50),
	declared_monthly_revenue Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Crm_customers_dataset','U') Is Not Null
	Drop Table Bronze.Crm_customers_dataset;

Create Table Bronze.Crm_customers_dataset(
	customer_id Nvarchar(50),
	customer_unique_id Nvarchar(50),
	customer_zip_code_prefix Nvarchar(20),
	customer_city Nvarchar(100),
	customer_state Nvarchar(10),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Crm_marketing_qualified_leads','U') Is Not Null
	Drop Table Bronze.Crm_marketing_qualified_leads;

Create Table Bronze.Crm_marketing_qualified_leads(
	mql_id Nvarchar(50),
	first_contact_date Nvarchar(50),
	landing_page_id Nvarchar(50),
	origin Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Crm_order_reviews','U') Is Not Null
	Drop Table Bronze.Crm_order_reviews;

Create Table Bronze.Crm_order_reviews(
	review_id Nvarchar(50),
	order_id Nvarchar(50),
	review_score Nvarchar(10),
	review_comment_title Nvarchar(max),
	review_comment_message Nvarchar(max),
	review_creation_date Nvarchar(50),
	review_answer_timestamp Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_order_items','U') Is Not Null
	Drop Table Bronze.Erp_order_items;

Create Table Bronze.Erp_order_items(
	order_id Nvarchar(50),
	order_item_id Nvarchar(10),
	product_id Nvarchar(50),
	seller_id Nvarchar(50),
	shipping_limit_date Nvarchar(50),
	price Nvarchar(50),
	freight_value Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_order_payments','U') Is Not Null
	Drop Table Bronze.Erp_order_payments;

Create Table Bronze.Erp_order_payments(
	order_id Nvarchar(50),
	payment_sequential Nvarchar(10),
	payment_type Nvarchar(50),
	payment_installments Nvarchar(10),
	payment_value Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_products','U') Is Not Null
	Drop Table Bronze.Erp_products;

Create Table Bronze.Erp_products(
	product_id Nvarchar(50),
	product_category_name Nvarchar(100),
	product_name_length Nvarchar(10),
	product_description_length Nvarchar(10),
	product_photos_qty Nvarchar(10),
	product_weight_g Nvarchar(20),
	product_length_cm Nvarchar(20),
	product_height_cm Nvarchar(20),
	product_width_cm Nvarchar(20),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_sellers','U') Is Not Null
	Drop Table Bronze.Erp_sellers;

Create Table Bronze.Erp_sellers(
	seller_id Nvarchar(50),
	seller_zip_code_prefix Nvarchar(20),
	seller_city Nvarchar(100),
	seller_state Nvarchar(10),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_product_category_name_translation','U') Is Not Null
	Drop Table Bronze.Erp_product_category_name_translation;

Create Table Bronze.Erp_product_category_name_translation(
	product_category_name Nvarchar(max),
	product_category_name_english Nvarchar(max),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_geolocation','U') Is Not Null
	Drop Table Bronze.Erp_geolocation;

Create Table Bronze.Erp_geolocation(
	geolocation_zip_code_prefix Nvarchar(20),
	geolocation_lat Nvarchar(50),
	geolocation_lng Nvarchar(50),
	geolocation_city Nvarchar(100),
	geolocation_state Nvarchar(10),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go

If Object_Id('Bronze.Erp_orders','U') Is Not Null
	Drop Table Bronze.Erp_orders;

Create Table Bronze.Erp_orders(
	order_id Nvarchar(50),
	customer_id Nvarchar(50),
	order_status Nvarchar(50),
	order_purchase_timestamp Nvarchar(50),
	order_approved_at Nvarchar(50),
	order_delivered_carrier_date Nvarchar(50),
	order_delivered_customer_date Nvarchar(50),
	order_estimated_delivery_date Nvarchar(50),
	Batch_Id Uniqueidentifier Null,
	Load_Timestamp Datetime2 Default Sysdatetime(),
	Source_File Nvarchar(200) Null
);
Go