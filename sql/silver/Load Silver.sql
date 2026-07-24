Create Or Alter Procedure Silver.Load_Silver
As
Begin
	Set Nocount On;

	Declare @Batch_Id        Uniqueidentifier = Newid();
	Declare @Batch_Start     Datetime2        = Sysdatetime();
	Declare @Batch_End       Datetime2;
	Declare @Batch_Duration  Int;

	Declare @Table_Name        Nvarchar(150) = 'Silver.Load_Silver (Clearing Phase)';
	Declare @Source_Batch_Id   Uniqueidentifier;
	Declare @Load_Start        Datetime2;
	Declare @Load_End          Datetime2;
	Declare @Load_Duration     Int;
	Declare @Source_Row_Count  Bigint;
	Declare @Rows_Inserted     Bigint;
	Declare @Target_Row_Count  Bigint;

	Begin Try

	Print '=================================================';
	Print '== Silver Layer Load Started: ' + Convert(Nvarchar, @Batch_Start, 120);
	Print '=================================================';

	-- ── Clear tables. Truncate where nothing points at them via FK;
	--    Delete where a FK constraint from another table exists — Truncate
	--    is blocked by SQL Server the moment ANY FK references a table,
	--    even if the referencing table is already empty.
	Print '-- >> Clearing Silver tables';
	Truncate Table Silver.Erp_order_items;
	Truncate Table Silver.Erp_order_payments;
	Truncate Table Silver.Crm_order_reviews;
	Truncate Table Silver.Crm_closed_deals;
	Truncate Table Silver.Crm_marketing_qualified_leads;
	Delete From Silver.Erp_orders;              -- referenced by Erp_order_items / Erp_order_payments
	Truncate Table Silver.Erp_product_category_name_translation;
	Truncate Table Silver.Erp_geolocation;
	Delete From Silver.Crm_customers;           -- referenced by Erp_orders
	Delete From Silver.Erp_products;            -- referenced by Erp_order_items
	Delete From Silver.Erp_sellers;             -- referenced by Erp_order_items

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Crm_customers
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Crm_customers';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Crm_customers_dataset);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Crm_customers_dataset);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	;With CleanedCustomers As (
		Select
			customer_id, customer_unique_id, customer_zip_code_prefix,
			Upper(Trim(customer_state)) As customer_state,
			Trim(Replace(Replace(Translate(Lower(Trim(customer_city)), 'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn'), Char(13), ''), Char(10), '')) As raw_clean_city
		From Bronze.Crm_customers_dataset
	)
	Insert Into Silver.Crm_customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, Batch_Id)
	Select customer_id, customer_unique_id, customer_zip_code_prefix, Silver.Fn_Correct_Known_City(raw_clean_city), customer_state, @Batch_Id
	From CleanedCustomers;

	Set @Rows_Inserted = (Select Count(*) From Silver.Crm_customers);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_products
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_products';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_products);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_products);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Erp_products (product_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm, Batch_Id)
	Select
		product_id,
		Trim(Replace(product_category_name,'_',' ')),
		Try_Cast(Try_Cast(product_name_length As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(product_description_length As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(product_photos_qty As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(product_weight_g As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(product_length_cm As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(product_height_cm As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(product_width_cm As Decimal(18,2)) As Int),
		@Batch_Id
	From Bronze.Erp_products;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_products);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_sellers
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_sellers';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_sellers);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_sellers);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	;With CleanedSellers As (
		Select
			Trim(seller_id)seller_id, seller_zip_code_prefix,
			Upper(Trim(seller_state)) As seller_state,
			Trim(Replace(Replace(Translate(Lower(Trim(seller_city)), 'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn'), Char(13), ''), Char(10), '')) As raw_clean_city
		From Bronze.Erp_sellers
	)
	Insert Into Silver.Erp_sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state, Batch_Id)
	Select seller_id, seller_zip_code_prefix, Silver.Fn_Correct_Known_City(raw_clean_city), seller_state, @Batch_Id
	From CleanedSellers;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_sellers);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_product_category_name_translation
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_product_category_name_translation';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_product_category_name_translation);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_product_category_name_translation);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Erp_product_category_name_translation (product_category_name, product_category_name_english, Batch_Id)
	Select Trim(Replace(product_category_name,'_',' ')), Trim(Replace(product_category_name_english,'_',' ')), @Batch_Id
	From Bronze.Erp_product_category_name_translation;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_product_category_name_translation);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_geolocation
	-- Target_Row_Count is expected to be LOWER than Source_Row_Count —
	-- intentional dedup/averaging per zip. Not treated as a warning.
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_geolocation';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_geolocation);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_geolocation);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	With CleanedGeography As (
	Select Distinct
		geolocation_zip_code_prefix,
		Round(Avg(Try_Cast(geolocation_lat As Float)) Over(Partition By geolocation_zip_code_prefix), 5) As geolocation_lat,
		Round(Avg(Try_Cast(geolocation_lng As Float)) Over(Partition By geolocation_zip_code_prefix), 5) As geolocation_lng,
		Translate(Replace(Replace(Replace(Replace(Replace(Replace(Lower(Trim(geolocation_city)), '-', ' '), '...', ''), '´', ''), '%26apos%3b', ''''), '³', 'o'), '£', ''),
			'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn') As clean_city,
		Upper(Trim(geolocation_state)) As geolocation_state
	From Bronze.Erp_geolocation
),
RankedGeography As (
	Select
		geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
		Silver.Fn_Correct_Known_City(clean_city) As geolocation_city,
		geolocation_state,
		Row_Number() Over(Partition By geolocation_zip_code_prefix Order By Silver.Fn_Correct_Known_City(clean_city)) As Rn
	From CleanedGeography
)
Insert Into Silver.Erp_geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, Batch_Id)
Select geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, @Batch_Id
From RankedGeography
Where Rn = 1;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_geolocation);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count, 'SUCCESS');
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar) + ' (deduped from ' + Cast(@Source_Row_Count As Nvarchar) + ' source rows)';

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Crm_marketing_qualified_leads
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Crm_marketing_qualified_leads';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Crm_marketing_qualified_leads);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Crm_marketing_qualified_leads);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Crm_marketing_qualified_leads (mql_id, first_contact_date, landing_page_id, origin, Batch_Id)
	Select mql_id, Try_Cast(first_contact_date As Date), landing_page_id, Trim(Replace(origin,'_',' ')), @Batch_Id
	From Bronze.Crm_marketing_qualified_leads;

	Set @Rows_Inserted = (Select Count(*) From Silver.Crm_marketing_qualified_leads);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Crm_closed_deals
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Crm_closed_deals';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Crm_closed_deals);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Crm_closed_deals);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Crm_closed_deals (mql_id, seller_id, sdr_id, sr_id, won_date, business_segment, lead_type, lead_behaviour_profile, has_company, has_gtin, average_stock, business_type, declared_product_catalog_size, declared_monthly_revenue, Batch_Id)
	Select
		mql_id, seller_id, sdr_id, sr_id,
		Try_Cast(won_date As Datetime2),
		Trim(Replace(business_segment,'_',' ')),
		Trim(Replace(lead_type,'_',' ')),
		Case When Upper(Trim(lead_behaviour_profile)) = 'INVALID' Or Trim(lead_behaviour_profile) = '' Then Null Else Trim(lead_behaviour_profile) End,
		Try_Cast(has_company As Bit),
		Try_Cast(has_gtin As Bit),
		Case When Trim(average_stock) = 'unknown' Then Null Else Trim(average_stock) End,
		Trim(business_type),
		Try_Cast(Try_Cast(declared_product_catalog_size As Decimal(18,2)) As Int),
		Try_Cast(Try_Cast(declared_monthly_revenue As Decimal(18,2)) As Int),
		@Batch_Id
	From Bronze.Crm_closed_deals;

	Set @Rows_Inserted = (Select Count(*) From Silver.Crm_closed_deals);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_orders  (depends on Crm_customers)
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_orders';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_orders);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_orders);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Erp_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, Batch_Id)
	Select
		order_id, customer_id, Trim(order_status),
		Try_Cast(order_purchase_timestamp As Datetime2),
		Try_Cast(order_approved_at As Datetime2),
		Try_Cast(order_delivered_carrier_date As Datetime2),
		Try_Cast(order_delivered_customer_date As Datetime2),
		Try_Cast(order_estimated_delivery_date As Datetime2),
		@Batch_Id
	From Bronze.Erp_orders;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_orders);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_order_items  (depends on Orders, Products, Sellers)
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_order_items';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_order_items);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_order_items);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Erp_order_items (order_id, order_item_number, product_id, seller_id, shipping_limit_date, price, freight_value, Batch_Id)
	Select
		Trim(order_id)order_id, Try_Cast(order_item_id As Int), Trim(product_id), Trim(seller_id),
		Try_Cast(shipping_limit_date As Datetime2),
		Try_Cast(price As Decimal(12,2)),
		Try_Cast(freight_value As Decimal(12,2)),
		@Batch_Id
	From Bronze.Erp_order_items;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_order_items);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Erp_order_payments  (depends on Orders)
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Erp_order_payments';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Erp_order_payments);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Erp_order_payments);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Erp_order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value, Batch_Id)
	Select
		order_id, Try_Cast(payment_sequential As Int), Trim(Replace(payment_type,'_',' ')),
		Try_Cast(payment_installments As Int),
		Try_Cast(payment_value As Decimal(12,2)),
		@Batch_Id
	From Bronze.Erp_order_payments;

	Set @Rows_Inserted = (Select Count(*) From Silver.Erp_order_payments);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ════════════════════════════════════════════════════════════════
	-- TABLE: Silver.Crm_order_reviews
	-- ════════════════════════════════════════════════════════════════
	Set @Table_Name = 'Silver.Crm_order_reviews';
	Set @Load_Start = Sysdatetime();
	Set @Source_Batch_Id  = (Select Max(Batch_Id) From Bronze.Crm_order_reviews);
	Set @Source_Row_Count = (Select Count(*) From Bronze.Crm_order_reviews);

	Print '-- >> Transforming & Inserting: ' + @Table_Name;

	Insert Into Silver.Crm_order_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp, Batch_Id)
	Select
		review_id, order_id, Try_Cast(review_score As Int), review_comment_title, review_comment_message,
		Try_Cast(review_creation_date As Date),
		Try_Cast(review_answer_timestamp As Datetime2),
		@Batch_Id
	From Bronze.Crm_order_reviews;

	Set @Rows_Inserted = (Select Count(*) From Silver.Crm_order_reviews);
	Set @Target_Row_Count = @Rows_Inserted;
	Set @Load_End = Sysdatetime();
	Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);

	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Source_Row_Count, Rows_Inserted, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Source_Row_Count, @Rows_Inserted, @Target_Row_Count,
			Case When @Target_Row_Count = @Source_Row_Count Then 'SUCCESS' Else 'WARNING' End);
	Print '   [OK] Rows: ' + Cast(@Rows_Inserted As Nvarchar);

	-- ── Batch close ──────────────────────────────────────────────────
	Set @Batch_End = Sysdatetime();
	Set @Batch_Duration = Datediff(Second, @Batch_Start, @Batch_End);

	Update Audit.ETL_Log
	Set Batch_End_Time = @Batch_End, Batch_Duration_Sec = @Batch_Duration
	Where Batch_Id = @Batch_Id;

	Print '=================================================';
	Print '      Silver Layer Load Completed';
	Print '  ->> Total Duration: ' + Cast(@Batch_Duration As Nvarchar) + ' Seconds';
	Print '=================================================';

	End Try
	Begin Catch
		Update Audit.ETL_Log
		Set Batch_End_Time = Sysdatetime(), Batch_Duration_Sec = Datediff(Second, @Batch_Start, Sysdatetime())
		Where Batch_Id = @Batch_Id And Batch_End_Time Is Null;

		Insert Into Audit.ETL_Log
			(Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Status, Error_Message, Error_Number, Error_State)
		Values
			(@Batch_Id, 'Silver', @Table_Name, 'Silver.Load_Silver', @Batch_Start, @Load_Start, Sysdatetime(), 'FAILED', Error_Message(), Error_Number(), Error_State());

		Print '=================================================';
		Print '    Error Occurred During Loading Silver Layer';
		Print '=================================================';

		Throw;
	End Catch
End
Go