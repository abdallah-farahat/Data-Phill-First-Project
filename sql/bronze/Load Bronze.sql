Create Or Alter Procedure Bronze.Load_Bronze 
As
Begin
    Set Nocount On;

    Declare @CrmPath Nvarchar(500) = 'F:\Abdallah Work\Abdallah College\DataPill\First Project\DataSet\CRM\';
    Declare @ErpPath Nvarchar(500) = 'F:\Abdallah Work\Abdallah College\DataPill\First Project\DataSet\ERP\';

    -- ── Batch-level variables ─────────────────────────────────────────
    Declare @Batch_Id          Uniqueidentifier = Newid();
    Declare @Batch_Start       Datetime2        = Sysdatetime();
    Declare @Batch_End         Datetime2;
    Declare @Batch_Duration    Int;

    -- ── Table-level variables ─────────────────────────────────────────
    Declare @Table_Name        Nvarchar(150);
    Declare @File_Name         Nvarchar(200);
    Declare @Load_Start        Datetime2;
    Declare @Load_End          Datetime2;
    Declare @Load_Duration     Int;
    Declare @Rows_Inserted     Int;
    Declare @Target_Count      Int;
    Declare @BulkSQL           Nvarchar(Max);

    Begin Try

    Print '=================================================';
    Print '== Bronze Layer Load Started: ' + Convert(Nvarchar, @Batch_Start, 120);
    Print '=================================================';

    -- ════════════════════════════════════════════════════════════════
    -- 1. CRM TABLES
    -- ════════════════════════════════════════════════════════════════

    -- TABLE: Bronze.Crm_closed_deals
    Set @Table_Name  = 'Bronze.Crm_closed_deals';
    Set @File_Name   = 'olist_closed_deals_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Crm_closed_deals;
    Set @BulkSQL = 'Bulk Insert Staging.Crm_closed_deals From ''' + @CrmPath + @File_Name + ''' With (Format = ''CSV'', Firstrow = 2, Fieldquote = ''"'', Rowterminator = ''0x0a'', Tablock, Codepage = ''65001'');';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Crm_closed_deals (mql_id, seller_id, sdr_id, sr_id, won_date, business_segment, lead_type, lead_behaviour_profile, has_company, has_gtin, average_stock, business_type, declared_product_catalog_size, declared_monthly_revenue, Batch_Id, Load_Timestamp, Source_File)
    Select S.mql_id, S.seller_id, S.sdr_id, S.sr_id, S.won_date, S.business_segment, S.lead_type, S.lead_behaviour_profile, S.has_company, S.has_gtin, S.average_stock, S.business_type, S.declared_product_catalog_size, S.declared_monthly_revenue, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Crm_closed_deals S
    Where Not Exists (Select 1 From Bronze.Crm_closed_deals B Where B.mql_id = S.mql_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Crm_closed_deals Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Crm_customers_dataset
    Set @Table_Name  = 'Bronze.Crm_customers_dataset';
    Set @File_Name   = 'olist_customers_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Crm_customers_dataset;
    
    Set @BulkSQL = 'Bulk Insert Staging.Crm_customers_dataset From ''' + @CrmPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Crm_customers_dataset (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state, Batch_Id, Load_Timestamp, Source_File)
    Select S.customer_id, S.customer_unique_id, S.customer_zip_code_prefix, S.customer_city, S.customer_state, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Crm_customers_dataset S
    Where Not Exists (Select 1 From Bronze.Crm_customers_dataset B Where B.customer_id = S.customer_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Crm_customers_dataset Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Crm_marketing_qualified_leads
    Set @Table_Name  = 'Bronze.Crm_marketing_qualified_leads';
    Set @File_Name   = 'olist_marketing_qualified_leads_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Crm_marketing_qualified_leads;
    
    Set @BulkSQL = 'Bulk Insert Staging.Crm_marketing_qualified_leads From ''' + @CrmPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Crm_marketing_qualified_leads (mql_id, first_contact_date, landing_page_id, origin, Batch_Id, Load_Timestamp, Source_File)
    Select S.mql_id, S.first_contact_date, S.landing_page_id, S.origin, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Crm_marketing_qualified_leads S
    Where Not Exists (Select 1 From Bronze.Crm_marketing_qualified_leads B Where B.mql_id = S.mql_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Crm_marketing_qualified_leads Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Crm_order_reviews
    Set @Table_Name  = 'Bronze.Crm_order_reviews';
    Set @File_Name   = 'olist_order_reviews_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Crm_order_reviews;
    
    Set @BulkSQL = 'Bulk Insert Staging.Crm_order_reviews From ''' + @CrmPath + @File_Name + ''' With (Format = ''CSV'', Firstrow = 2, Fieldquote = ''"'', Rowterminator=''0x0a'', Tablock, Codepage = ''65001'');';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Crm_order_reviews (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp, Batch_Id, Load_Timestamp, Source_File)
    Select S.review_id, S.order_id, S.review_score, S.review_comment_title, S.review_comment_message, S.review_creation_date, S.review_answer_timestamp, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Crm_order_reviews S
    Where Not Exists (Select 1 From Bronze.Crm_order_reviews B Where B.review_id = S.review_id And B.order_id = S.order_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Crm_order_reviews Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- ════════════════════════════════════════════════════════════════
    -- 2. ERP TABLES
    -- ════════════════════════════════════════════════════════════════

    -- TABLE: Bronze.Erp_order_items
    Set @Table_Name  = 'Bronze.Erp_order_items';
    Set @File_Name   = 'olist_order_items_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_order_items;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_order_items From ''' + @ErpPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Erp_order_items (order_id, order_item_id, product_id, seller_id, shipping_limit_date, price, freight_value, Batch_Id, Load_Timestamp, Source_File)
    Select S.order_id, S.order_item_id, S.product_id, S.seller_id, S.shipping_limit_date, S.price, S.freight_value, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_order_items S
    Where Not Exists (Select 1 From Bronze.Erp_order_items B Where B.order_id = S.order_id And B.order_item_id = S.order_item_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_order_items Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Erp_order_payments
    Set @Table_Name  = 'Bronze.Erp_order_payments';
    Set @File_Name   = 'olist_order_payments_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_order_payments;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_order_payments From ''' + @ErpPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Erp_order_payments (order_id, payment_sequential, payment_type, payment_installments, payment_value, Batch_Id, Load_Timestamp, Source_File)
    Select S.order_id, S.payment_sequential, S.payment_type, S.payment_installments, S.payment_value, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_order_payments S
    Where Not Exists (Select 1 From Bronze.Erp_order_payments B Where B.order_id = S.order_id And B.payment_sequential = S.payment_sequential);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_order_payments Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Erp_products
    Set @Table_Name  = 'Bronze.Erp_products';
    Set @File_Name   = 'olist_products_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_products;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_products From ''' + @ErpPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Erp_products (product_id, product_category_name, product_name_length, product_description_length, product_photos_qty, product_weight_g, product_length_cm, product_height_cm, product_width_cm, Batch_Id, Load_Timestamp, Source_File)
    Select S.product_id, S.product_category_name, S.product_name_length, S.product_description_length, S.product_photos_qty, S.product_weight_g, S.product_length_cm, S.product_height_cm, S.product_width_cm, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_products S
    Where Not Exists (Select 1 From Bronze.Erp_products B Where B.product_id = S.product_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_products Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Erp_sellers
    Set @Table_Name  = 'Bronze.Erp_sellers';
    Set @File_Name   = 'olist_sellers_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_sellers;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_sellers From ''' + @ErpPath + @File_Name + ''' With (Format = ''CSV'', Firstrow = 2, Fieldquote = ''"'', Rowterminator = ''0x0a'', Tablock, Codepage = ''65001'');';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Erp_sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state, Batch_Id, Load_Timestamp, Source_File)
    Select S.seller_id, S.seller_zip_code_prefix, S.seller_city, S.seller_state, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_sellers S
    Where Not Exists (Select 1 From Bronze.Erp_sellers B Where B.seller_id = S.seller_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_sellers Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Erp_product_category_name_translation
    Set @Table_Name  = 'Bronze.Erp_product_category_name_translation';
    Set @File_Name   = 'product_category_name_translation.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_product_category_name_translation;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_product_category_name_translation From ''' + @ErpPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Erp_product_category_name_translation (product_category_name, product_category_name_english, Batch_Id, Load_Timestamp, Source_File)
    Select S.product_category_name, S.product_category_name_english, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_product_category_name_translation S
    Where Not Exists (Select 1 From Bronze.Erp_product_category_name_translation B Where B.product_category_name = S.product_category_name);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_product_category_name_translation Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Erp_geolocation
    Set @Table_Name  = 'Bronze.Erp_geolocation';
    Set @File_Name   = 'olist_geolocation_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_geolocation;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_geolocation From ''' + @ErpPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    Insert Into Bronze.Erp_geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, Batch_Id, Load_Timestamp, Source_File)
    Select S.geolocation_zip_code_prefix, S.geolocation_lat, S.geolocation_lng, S.geolocation_city, S.geolocation_state, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_geolocation S
    Where Not Exists (
    Select 1 From Bronze.Erp_geolocation B
    Where Isnull(B.geolocation_zip_code_prefix, '') = Isnull(S.geolocation_zip_code_prefix, '')
      And Isnull(B.geolocation_lat, '') = Isnull(S.geolocation_lat, '')
      And Isnull(B.geolocation_lng, '') = Isnull(S.geolocation_lng, '')
    );
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_geolocation Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- TABLE: Bronze.Erp_orders
    Set @Table_Name  = 'Bronze.Erp_orders';
    Set @File_Name   = 'olist_orders_dataset.csv';
    Set @Load_Start  = Sysdatetime();
    Print '-- >> Processing: ' + @Table_Name;
    
    Truncate Table Staging.Erp_orders;
    
    Set @BulkSQL = 'Bulk Insert Staging.Erp_orders From ''' + @ErpPath + @File_Name + ''' With (Firstrow=2, Fieldterminator='','', Rowterminator=''0x0a'', Codepage = ''65001'', Tablock);';
    Exec(@BulkSQL);
    
    Insert Into Bronze.Erp_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, Batch_Id, Load_Timestamp, Source_File)
    Select S.order_id, S.customer_id, S.order_status, S.order_purchase_timestamp, S.order_approved_at, S.order_delivered_carrier_date, S.order_delivered_customer_date, S.order_estimated_delivery_date, @Batch_Id, Sysdatetime(), @File_Name
    From Staging.Erp_orders S
    Where Not Exists (Select 1 From Bronze.Erp_orders B Where B.order_id = S.order_id);
    
    Set @Rows_Inserted = @@ROWCOUNT;
    Set @Target_Count = (Select Count(*) From Bronze.Erp_orders Where Batch_Id = @Batch_Id);
    Set @Load_End = Sysdatetime();
    Set @Load_Duration = Datediff(Second, @Load_Start, @Load_End);
    
    Insert Into Audit.ETL_Log (Batch_Id, Layer_Name, Table_Name, Procedure_Name, Batch_Start_Time, Load_Start_Time, Load_End_Time, Load_Duration_Sec, Rows_Inserted, Target_Row_Count, Status)
    Values (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze', @Batch_Start, @Load_Start, @Load_End, @Load_Duration, @Rows_Inserted, @Target_Count, Case When @Target_Count = @Rows_Inserted Then 'SUCCESS' Else 'WARNING' End);
    Print '   [OK] Load Duration: ' + Cast(@Load_Duration As Nvarchar) + ' Seconds. Rows: ' + Cast(@Rows_Inserted As Nvarchar);

    -- ── Batch close ──────────────────────────────────────────────────
    Set @Batch_End      = Sysdatetime();
    Set @Batch_Duration = Datediff(Second, @Batch_Start, @Batch_End);

    Update Audit.ETL_Log
    Set Batch_End_Time      = @Batch_End,
        Batch_Duration_Sec  = @Batch_Duration
    Where Batch_Id = @Batch_Id;

    Print '=================================================';
    Print '      Total Bronze Layer Is Completed';
    Print '  ->> Total Load Duration: ' + Cast(@Batch_Duration As Nvarchar) + ' Seconds';
    Print '=================================================';

    End Try
    Begin Catch
        Update Audit.ETL_Log
        Set Batch_End_Time = Sysdatetime(),
            Batch_Duration_Sec = Datediff(Second, @Batch_Start, Sysdatetime())
        Where Batch_Id = @Batch_Id
          And Batch_End_Time Is Null;

        Insert Into Audit.ETL_Log
            (Batch_Id, Layer_Name, Table_Name, Procedure_Name,
             Batch_Start_Time, Load_Start_Time, Load_End_Time,
             Rows_Inserted, Status,
             Error_Message, Error_Number, Error_State)
        Values
            (@Batch_Id, 'Bronze', @Table_Name, 'Bronze.Load_Bronze',
             @Batch_Start, @Load_Start, Sysdatetime(),
             @Rows_Inserted, 'FAILED',
             Error_Message(), Error_Number(), Error_State());

        Print '=================================================';
        Print '    Error Occurred During Loading Bronze Layer';
        Print '=================================================';

        Throw;
    End Catch
End
Go