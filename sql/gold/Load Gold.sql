Create Or Alter Procedure Gold.Load_Gold
	@Start_Date Date = '2016-01-01',
	@End_Date Date = '2019-12-31'
As
Begin
	Set Nocount On;

	Declare @Batch_Id Uniqueidentifier = Newid();
	Declare @Batch_Start Datetime2 = Sysdatetime();
	Declare @Batch_End Datetime2;
	Declare @Batch_Duration Int;
	Declare @Table_Name Nvarchar(150) = 'Gold.Load_Gold (Start)';
	Declare @Source_Batch_Id Uniqueidentifier;
	Declare @Load_Start Datetime2;
	Declare @Load_End Datetime2;
	Declare @Rows_Inserted Bigint;
	Declare @Rows_Updated Bigint;
	Declare @Target_Row_Count Bigint;
	Declare @MergeOutput Table (Action_Type Nvarchar(10));

	Begin Try

	Print 'Gold Layer Load Started: ' + Convert(Nvarchar, @Batch_Start, 120);

	-- ═════════ Dim_Date (generated, no Silver source) ═════════
	Set @Table_Name = 'Gold.Dim_Date';
	Set @Source_Batch_Id = Null;
	Set @Load_Start = Sysdatetime();

	With DateSeries As (
		Select @Start_Date As Full_Date
		Union All
		Select Dateadd(Day, 1, Full_Date) From DateSeries Where Full_Date < @End_Date
	)
	Insert Into Gold.Dim_Date (Date_Key, Full_Date, Year_Number, Quarter_Number, Month_Number, Month_Name, Day_Name, Is_Weekend)
	Select
		Convert(Int, Format(D.Full_Date, 'yyyyMMdd')), D.Full_Date, Year(D.Full_Date), Datepart(Quarter, D.Full_Date), Month(D.Full_Date),
		Datename(Month, D.Full_Date), Datename(Weekday, D.Full_Date),
		Case When Datename(Weekday, D.Full_Date) In ('Saturday','Sunday') Then 1 Else 0 End
	From DateSeries D
	Where Not Exists (Select 1 From Gold.Dim_Date Existing Where Existing.Date_Key = Convert(Int, Format(D.Full_Date, 'yyyyMMdd')))
	Option (MaxRecursion 0);

	Set @Rows_Inserted = @@Rowcount;
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, 'SUCCESS');

	-- ═════════ Dim_Product (Type 1) ═════════
	Set @Table_Name = 'Gold.Dim_Product';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Erp_products);
	Set @Load_Start = Sysdatetime();
	Delete From @MergeOutput;

	Merge Gold.Dim_Product As Target
	Using (
		Select p.product_id, p.product_category_name As Category_Name_Pt,
			Coalesce(t.product_category_name_english, p.product_category_name) As Category_Name_En,
			p.product_name_length, p.product_description_length, p.product_photos_qty,
			p.product_weight_g, p.product_length_cm, p.product_height_cm, p.product_width_cm
		From Silver.Erp_products p
		Left Join Silver.Erp_product_category_name_translation t On p.product_category_name = t.product_category_name
	) As Source
	On Target.product_id = Source.product_id
	When Matched Then Update Set
		Category_Name_Pt = Source.Category_Name_Pt, Category_Name_En = Source.Category_Name_En,
		product_name_length = Source.product_name_length, product_description_length = Source.product_description_length,
		product_photos_qty = Source.product_photos_qty, product_weight_g = Source.product_weight_g,
		product_length_cm = Source.product_length_cm, product_height_cm = Source.product_height_cm,
		product_width_cm = Source.product_width_cm, load_date_timestamp = Sysdatetime()
	When Not Matched By Target Then Insert (product_id, Category_Name_Pt, Category_Name_En, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm)
		Values (Source.product_id, Source.Category_Name_Pt, Source.Category_Name_En, Source.product_name_length, Source.product_description_length, Source.product_photos_qty, Source.product_weight_g, Source.product_length_cm, Source.product_height_cm, Source.product_width_cm)
	Output $action Into @MergeOutput;

	Select @Rows_Inserted = Count(*) From @MergeOutput Where Action_Type = 'INSERT';
	Select @Rows_Updated  = Count(*) From @MergeOutput Where Action_Type = 'UPDATE';
	Set @Target_Row_Count = (Select Count(*) From Gold.Dim_Product);
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, @Target_Row_Count, 'SUCCESS');

	-- ═════════ Dim_Seller (Type 2) ═════════
	Set @Table_Name = 'Gold.Dim_Seller';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Erp_sellers);
	Set @Load_Start = Sysdatetime();

	Update Target
	Set Target.Effective_End_Date = Sysdatetime(), Target.Is_Current = 0
	From Gold.Dim_Seller Target
	Inner Join Silver.Erp_sellers Source On Target.seller_id = Source.seller_id
	Where Target.Is_Current = 1
	  And (Isnull(Target.seller_city,'') <> Isnull(Source.seller_city,'') Or Isnull(Target.seller_state,'') <> Isnull(Source.seller_state,''));

	Set @Rows_Updated = @@Rowcount;

	Insert Into Gold.Dim_Seller (seller_id, seller_zip_code_prefix, seller_city, seller_state, geolocation_lat, geolocation_lng, Effective_Start_Date, Effective_End_Date, Is_Current)
	Select S.seller_id, S.seller_zip_code_prefix, S.seller_city, S.seller_state, G.geolocation_lat, G.geolocation_lng, Sysdatetime(), Null, 1
	From Silver.Erp_sellers S
	Left Join Silver.Erp_geolocation G On S.seller_zip_code_prefix = G.geolocation_zip_code_prefix
	Where Not Exists (Select 1 From Gold.Dim_Seller D Where D.seller_id = S.seller_id And D.Is_Current = 1);

	Set @Rows_Inserted = @@Rowcount;
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, 'SUCCESS');

	-- ═════════ Dim_Customer (Type 2) ═════════
	Set @Table_Name = 'Gold.Dim_Customer';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Crm_customers);
	Set @Load_Start = Sysdatetime();

	With CustomerRolledUp As (
		Select customer_unique_id, Max(customer_zip_code_prefix) As customer_zip_code_prefix,
			Max(customer_city) As customer_city, Max(customer_state) As customer_state
		From Silver.Crm_customers
		Group By customer_unique_id
	)
	Update Target
	Set Target.Effective_End_Date = Sysdatetime(), Target.Is_Current = 0
	From Gold.Dim_Customer Target
	Inner Join CustomerRolledUp Source On Target.customer_unique_id = Source.customer_unique_id
	Where Target.Is_Current = 1
	  And (Isnull(Target.customer_city,'') <> Isnull(Source.customer_city,'') Or Isnull(Target.customer_state,'') <> Isnull(Source.customer_state,''));

	Set @Rows_Updated = @@Rowcount;

	With CustomerRolledUp2 As (
		Select customer_unique_id, Max(customer_zip_code_prefix) As customer_zip_code_prefix,
			Max(customer_city) As customer_city, Max(customer_state) As customer_state
		From Silver.Crm_customers
		Group By customer_unique_id
	)
	Insert Into Gold.Dim_Customer (customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, geolocation_lat, geolocation_lng, Effective_Start_Date, Effective_End_Date, Is_Current)
	Select C.customer_unique_id, C.customer_zip_code_prefix, C.customer_city, C.customer_state, G.geolocation_lat, G.geolocation_lng, Sysdatetime(), Null, 1
	From CustomerRolledUp2 C
	Left Join Silver.Erp_geolocation G On C.customer_zip_code_prefix = G.geolocation_zip_code_prefix
	Where Not Exists (Select 1 From Gold.Dim_Customer D Where D.customer_unique_id = C.customer_unique_id And D.Is_Current = 1);

	Set @Rows_Inserted = @@Rowcount;
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, 'SUCCESS');

	-- ═════════ Fact_Orders ═════════
	Set @Table_Name = 'Gold.Fact_Orders';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Erp_orders);
	Set @Load_Start = Sysdatetime();
	Delete From @MergeOutput;

	Merge Gold.Fact_Orders As Target
	Using (
		Select
			o.order_id,
			Coalesce(dc.Customer_Key, -1) As Customer_Key,
			Convert(Int, Format(o.order_purchase_timestamp, 'yyyyMMdd')) As Purchase_Date_Key,
			Case When o.order_delivered_customer_date Is Not Null Then Convert(Int, Format(o.order_delivered_customer_date, 'yyyyMMdd')) Else Null End As Delivered_Date_Key,
			Case When o.order_estimated_delivery_date Is Not Null Then Convert(Int, Format(o.order_estimated_delivery_date, 'yyyyMMdd')) Else Null End As Estimated_Delivery_Date_Key,
			o.order_status,
			Case When o.order_status In ('canceled','unavailable') Then 0 Else 1 End As Is_Revenue_Eligible,
			o.order_approved_at, o.order_delivered_carrier_date
		From Silver.Erp_orders o
		Left Join Silver.Crm_customers c On o.customer_id = c.customer_id
		Left Join Gold.Dim_Customer dc On c.customer_unique_id = dc.customer_unique_id And dc.Is_Current = 1
	) As Source
	On Target.order_id = Source.order_id
	When Matched Then Update Set
		Customer_Key = Source.Customer_Key, Purchase_Date_Key = Source.Purchase_Date_Key, Delivered_Date_Key = Source.Delivered_Date_Key,
		Estimated_Delivery_Date_Key = Source.Estimated_Delivery_Date_Key, order_status = Source.order_status,
		Is_Revenue_Eligible = Source.Is_Revenue_Eligible, order_approved_at = Source.order_approved_at,
		order_delivered_carrier_date = Source.order_delivered_carrier_date, Batch_Id = @Batch_Id, load_date_timestamp = Sysdatetime()
	When Not Matched By Target Then Insert (order_id, Customer_Key, Purchase_Date_Key, Delivered_Date_Key, Estimated_Delivery_Date_Key, order_status, Is_Revenue_Eligible, order_approved_at, order_delivered_carrier_date, Batch_Id)
		Values (Source.order_id, Source.Customer_Key, Source.Purchase_Date_Key, Source.Delivered_Date_Key, Source.Estimated_Delivery_Date_Key, Source.order_status, Source.Is_Revenue_Eligible, Source.order_approved_at, Source.order_delivered_carrier_date, @Batch_Id)
	Output $action Into @MergeOutput;

	Select @Rows_Inserted = Count(*) From @MergeOutput Where Action_Type = 'INSERT';
	Select @Rows_Updated  = Count(*) From @MergeOutput Where Action_Type = 'UPDATE';
	Set @Target_Row_Count = (Select Count(*) From Gold.Fact_Orders);
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, @Target_Row_Count, 'SUCCESS');

	-- ═════════ Fact_Order_Items ═════════
	Set @Table_Name = 'Gold.Fact_Order_Items';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Erp_order_items);
	Set @Load_Start = Sysdatetime();
	Delete From @MergeOutput;

	Merge Gold.Fact_Order_Items As Target
	Using (
		Select
			oi.order_id, oi.order_item_number,
			Coalesce(dp.Product_Key, -1) As Product_Key,
			Coalesce(ds.Seller_Key, -1) As Seller_Key,
			Convert(Int, Format(o.order_purchase_timestamp, 'yyyyMMdd')) As Purchase_Date_Key,
			oi.price, oi.freight_value,
			Case When o.order_status In ('canceled','unavailable') Then 0 Else 1 End As Is_Revenue_Eligible
		From Silver.Erp_order_items oi
		Inner Join Silver.Erp_orders o On oi.order_id = o.order_id
		Left Join Gold.Dim_Product dp On oi.product_id = dp.product_id
		Left Join Gold.Dim_Seller ds On oi.seller_id = ds.seller_id And ds.Is_Current = 1
	) As Source
	On Target.order_id = Source.order_id And Target.order_item_number = Source.order_item_number
	When Matched Then Update Set
		Product_Key = Source.Product_Key, Seller_Key = Source.Seller_Key, Purchase_Date_Key = Source.Purchase_Date_Key,
		price = Source.price, freight_value = Source.freight_value, Is_Revenue_Eligible = Source.Is_Revenue_Eligible,
		Batch_Id = @Batch_Id, load_date_timestamp = Sysdatetime()
	When Not Matched By Target Then Insert (order_id, order_item_number, Product_Key, Seller_Key, Purchase_Date_Key, price, freight_value, Is_Revenue_Eligible, Batch_Id)
		Values (Source.order_id, Source.order_item_number, Source.Product_Key, Source.Seller_Key, Source.Purchase_Date_Key, Source.price, Source.freight_value, Source.Is_Revenue_Eligible, @Batch_Id)
	Output $action Into @MergeOutput;

	Select @Rows_Inserted = Count(*) From @MergeOutput Where Action_Type = 'INSERT';
	Select @Rows_Updated  = Count(*) From @MergeOutput Where Action_Type = 'UPDATE';
	Set @Target_Row_Count = (Select Count(*) From Gold.Fact_Order_Items);
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, @Target_Row_Count, 'SUCCESS');

	-- ═════════ Fact_Payments ═════════
	Set @Table_Name = 'Gold.Fact_Payments';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Erp_order_payments);
	Set @Load_Start = Sysdatetime();
	Delete From @MergeOutput;

	Merge Gold.Fact_Payments As Target
	Using Silver.Erp_order_payments As Source
	On Target.order_id = Source.order_id And Target.payment_sequential = Source.payment_sequential
	When Matched Then Update Set payment_type = Source.payment_type, payment_installments = Source.payment_installments,
		payment_value = Source.payment_value, Batch_Id = @Batch_Id, load_date_timestamp = Sysdatetime()
	When Not Matched By Target Then Insert (order_id, payment_sequential, payment_type, payment_installments, payment_value, Batch_Id)
		Values (Source.order_id, Source.payment_sequential, Source.payment_type, Source.payment_installments, Source.payment_value, @Batch_Id)
	Output $action Into @MergeOutput;

	Select @Rows_Inserted = Count(*) From @MergeOutput Where Action_Type = 'INSERT';
	Select @Rows_Updated  = Count(*) From @MergeOutput Where Action_Type = 'UPDATE';
	Set @Target_Row_Count = (Select Count(*) From Gold.Fact_Payments);
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, @Target_Row_Count, 'SUCCESS');

	-- ═════════ Fact_Reviews (only orders with an actual review) ═════════
	Set @Table_Name = 'Gold.Fact_Reviews';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Crm_order_reviews);
	Set @Load_Start = Sysdatetime();
	Delete From @MergeOutput;

	Merge Gold.Fact_Reviews As Target
	Using (
		Select r.review_id, r.order_id, r.review_score, r.review_comment_title, r.review_comment_message,
			Convert(Int, Format(r.review_creation_date, 'yyyyMMdd')) As Review_Creation_Date_Key,
			r.review_answer_timestamp
		From Silver.Crm_order_reviews r
		Where r.review_creation_date Is Not Null
	) As Source
	On Target.review_id = Source.review_id And Target.order_id = Source.order_id
	When Matched Then Update Set review_score = Source.review_score, review_comment_title = Source.review_comment_title,
		review_comment_message = Source.review_comment_message, Review_Creation_Date_Key = Source.Review_Creation_Date_Key,
		review_answer_timestamp = Source.review_answer_timestamp, Batch_Id = @Batch_Id, load_date_timestamp = Sysdatetime()
	When Not Matched By Target Then Insert (review_id, order_id, review_score, review_comment_title, review_comment_message, Review_Creation_Date_Key, review_answer_timestamp, Batch_Id)
		Values (Source.review_id, Source.order_id, Source.review_score, Source.review_comment_title, Source.review_comment_message, Source.Review_Creation_Date_Key, Source.review_answer_timestamp, @Batch_Id)
	Output $action Into @MergeOutput;

	Select @Rows_Inserted = Count(*) From @MergeOutput Where Action_Type = 'INSERT';
	Select @Rows_Updated  = Count(*) From @MergeOutput Where Action_Type = 'UPDATE';
	Set @Target_Row_Count = (Select Count(*) From Gold.Fact_Reviews);
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, @Target_Row_Count, 'SUCCESS');

	-- ═════════ Fact_Marketing_Funnel (leads left-joined to closed deals) ═════════
	Set @Table_Name = 'Gold.Fact_Marketing_Funnel';
	Set @Source_Batch_Id = (Select Max(Batch_Id) From Silver.Crm_marketing_qualified_leads);
	Set @Load_Start = Sysdatetime();
	Delete From @MergeOutput;

	Merge Gold.Fact_Marketing_Funnel As Target
	Using (
		Select
			mql.mql_id,
			Coalesce(ds.Seller_Key, -1) As Seller_Key,
			Convert(Int, Format(mql.first_contact_date, 'yyyyMMdd')) As First_Contact_Date_Key,
			Case When cd.won_date Is Not Null Then Convert(Int, Format(cd.won_date, 'yyyyMMdd')) Else Null End As Won_Date_Key,
			mql.landing_page_id, mql.origin,
			cd.sdr_id, cd.sr_id, cd.business_segment, cd.lead_type, cd.lead_behaviour_profile,
			cd.has_company, cd.has_gtin, cd.average_stock, cd.business_type,
			cd.declared_product_catalog_size, cd.declared_monthly_revenue,
			Case When cd.mql_id Is Not Null Then 1 Else 0 End As Is_Converted
		From Silver.Crm_marketing_qualified_leads mql
		Left Join Silver.Crm_closed_deals cd On mql.mql_id = cd.mql_id
		Left Join Gold.Dim_Seller ds On cd.seller_id = ds.seller_id And ds.Is_Current = 1
		Where mql.first_contact_date Is Not Null
	) As Source
	On Target.mql_id = Source.mql_id
	When Matched Then Update Set Seller_Key = Source.Seller_Key, First_Contact_Date_Key = Source.First_Contact_Date_Key,
		Won_Date_Key = Source.Won_Date_Key, landing_page_id = Source.landing_page_id, origin = Source.origin,
		sdr_id = Source.sdr_id, sr_id = Source.sr_id, business_segment = Source.business_segment, lead_type = Source.lead_type,
		lead_behaviour_profile = Source.lead_behaviour_profile, has_company = Source.has_company, has_gtin = Source.has_gtin,
		average_stock = Source.average_stock, business_type = Source.business_type,
		declared_product_catalog_size = Source.declared_product_catalog_size, declared_monthly_revenue = Source.declared_monthly_revenue,
		Is_Converted = Source.Is_Converted, Batch_Id = @Batch_Id, load_date_timestamp = Sysdatetime()
	When Not Matched By Target Then Insert (mql_id, Seller_Key, First_Contact_Date_Key, Won_Date_Key, landing_page_id, origin, sdr_id, sr_id, business_segment, lead_type, lead_behaviour_profile, has_company, has_gtin, average_stock, business_type, declared_product_catalog_size, declared_monthly_revenue, Is_Converted, Batch_Id)
		Values (Source.mql_id, Source.Seller_Key, Source.First_Contact_Date_Key, Source.Won_Date_Key, Source.landing_page_id, Source.origin, Source.sdr_id, Source.sr_id, Source.business_segment, Source.lead_type, Source.lead_behaviour_profile, Source.has_company, Source.has_gtin, Source.average_stock, Source.business_type, Source.declared_product_catalog_size, Source.declared_monthly_revenue, Source.Is_Converted, @Batch_Id)
	Output $action Into @MergeOutput;

	Select @Rows_Inserted = Count(*) From @MergeOutput Where Action_Type = 'INSERT';
	Select @Rows_Updated  = Count(*) From @MergeOutput Where Action_Type = 'UPDATE';
	Set @Target_Row_Count = (Select Count(*) From Gold.Fact_Marketing_Funnel);
	Set @Load_End = Sysdatetime();
	Insert Into Audit.ETL_Log (Batch_Id, Source_Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Rows_Updated, Target_Row_Count, Status)
	Values (@Batch_Id, @Source_Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, @Load_End, Datediff(Second,@Load_Start,@Load_End), @Rows_Inserted, @Rows_Updated, @Target_Row_Count, 'SUCCESS');

	-- ── Batch close ──
	Set @Batch_End = Sysdatetime();
	Set @Batch_Duration = Datediff(Second, @Batch_Start, @Batch_End);
	Update Audit.ETL_Log Set Batch_End_Time = @Batch_End, Batch_Duration_Sec = @Batch_Duration Where Batch_Id = @Batch_Id;

	Print 'Gold Layer Load Completed. Duration: ' + Cast(@Batch_Duration As Nvarchar) + ' Seconds';

	End Try
	Begin Catch
		Update Audit.ETL_Log Set Batch_End_Time = Sysdatetime(), Batch_Duration_Sec = Datediff(Second, @Batch_Start, Sysdatetime())
		Where Batch_Id = @Batch_Id And Batch_End_Time Is Null;

		Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Status, Error_Message, Error_Number, Error_State)
		Values (@Batch_Id, 'Gold', @Table_Name, 'Gold.Load_Gold', @Batch_Start, @Load_Start, Sysdatetime(), 'FAILED', Error_Message(), Error_Number(), Error_State());

		Print 'Error Occurred During Gold Layer Load';
		Throw;
	End Catch
End
Go