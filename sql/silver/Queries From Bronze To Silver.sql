-- Crm_closed_deals
Select
	mql_id,
	seller_id,
	sdr_id,
	sr_id,
	Try_Cast(won_date As Datetime2) As won_date,
	Trim(Replace(business_segment,'_',' ')) As business_segment,
	Trim(Replace(lead_type,'_',' ')) As lead_type,
	Case
		When Trim(lead_behaviour_profile) = 'Invalid' Then Null
		Else Trim(lead_behaviour_profile)
	End As lead_behaviour_profile,
	Try_Cast(has_company As Bit) As has_company,
	Try_Cast(has_gtin As Bit) As has_gtin,
	Case
		When Trim(average_stock) = 'unknown' Then Null 
		Else Trim(average_stock) 
	End As average_stock,
	Trim(business_type) As business_type,
	Try_Cast(Try_Cast(declared_product_catalog_size As Decimal(18,2)) As Int) As declared_product_catalog_size,
	Try_Cast(Try_Cast(declared_monthly_revenue As Decimal(18,2)) As Int) As declared_monthly_revenue
From Bronze.Crm_closed_deals;

-- Crm_marketing_qualified_leads
Select
	mql_id,
	Try_Cast(first_contact_date As Date) As first_contact_date,
	landing_page_id,
	Trim(Replace(origin,'_',' ')) As origin
From Bronze.Crm_marketing_qualified_leads;

-- Crm_order_reviews
Select
	review_id,
	order_id,
	Try_Cast(review_score As Int) As review_score,
	review_comment_title,
	review_comment_message,
	Try_Cast(review_creation_date As Date) As review_creation_date,
	Try_Cast(review_answer_timestamp As Datetime2) As review_answer_timestamp
From Bronze.Crm_order_reviews;

-- Erp_order_items
Select
	order_id,
	Try_Cast(order_item_id As Int) As order_item_number,
	product_id,
	seller_id,
	Try_Cast(shipping_limit_date As Datetime2) As shipping_limit_date,
	Try_Cast(price As Decimal(12,2)) As price,
	Try_Cast(freight_value As Decimal(12,2)) As freight_value
From Bronze.Erp_order_items;

-- Erp_order_payments
Select
	order_id,
	Try_Cast(payment_sequential As Int) As payment_sequential,
	Trim(Replace(payment_type,'_',' ')) As payment_type,
	Try_Cast(payment_installments As Int) As payment_installments,
	Try_Cast(payment_value As Decimal(12,2)) As payment_value
From Bronze.Erp_order_payments;

-- Erp_orders
Select
	order_id,
	customer_id,
	Trim(order_status) As order_status,
	Try_Cast(order_purchase_timestamp As Datetime2) As order_purchase_timestamp,
	Try_Cast(order_approved_at As Datetime2) As order_approved_at,
	Try_Cast(order_delivered_carrier_date As Datetime2) As order_delivered_carrier_date,
	Try_Cast(order_delivered_customer_date As Datetime2) As order_delivered_customer_date,
	Try_Cast(order_estimated_delivery_date As Datetime2) As order_estimated_delivery_date
From Bronze.Erp_orders;

-- Erp_product_category_name_translation
Select
	Trim(Replace(product_category_name,'_',' ')) As product_category_name,
	Trim(Replace(product_category_name_english,'_',' ')) As product_category_name_english
From Bronze.Erp_product_category_name_translation;

-- Erp_products
Select
	product_id,
	Trim(Replace(product_category_name,'_',' ')) As product_category_name,
	Try_Cast(Try_Cast(product_name_length As Decimal(18,2)) As Int) As product_name_length,
	Try_Cast(Try_Cast(product_description_length As Decimal(18,2)) As Int) As product_description_length,
	Try_Cast(Try_Cast(product_photos_qty As Decimal(18,2)) As Int) As product_photos_qty,
	Try_Cast(Try_Cast(product_weight_g As Decimal(18,2)) As Int) As product_weight_g,
	Try_Cast(Try_Cast(product_length_cm As Decimal(18,2)) As Int) As product_length_cm,
	Try_Cast(Try_Cast(product_height_cm As Decimal(18,2)) As Int) As product_height_cm,
	Try_Cast(Try_Cast(product_width_cm As Decimal(18,2)) As Int) As product_width_cm
From Bronze.Erp_products;

-- Erp_sellers
With CleanedSellers As (
	Select
		seller_id,
		seller_zip_code_prefix,
		Upper(Trim(seller_state)) As seller_state,
		Trim(Replace(Replace(Translate(Lower(Trim(seller_city)), 'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn'), Char(13), ''), Char(10), '')) As raw_clean_city
	From Bronze.Erp_sellers
)
Select
	seller_id,
	seller_zip_code_prefix,
	Silver.Fn_Correct_Known_City(raw_clean_city) As seller_city,
	seller_state
From CleanedSellers;

-- Crm_customers_dataset
With CleanedCustomers As (
	Select
		customer_id,
		customer_unique_id,
		customer_zip_code_prefix,
		Upper(Trim(customer_state)) As customer_state,
		Trim(Replace(Replace(Translate(Lower(Trim(customer_city)), 'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn'), Char(13), ''), Char(10), '')) As raw_clean_city
	From Bronze.Crm_customers_dataset
)
Select
	customer_id,
	customer_unique_id,
	customer_zip_code_prefix,
	Silver.Fn_Correct_Known_City(raw_clean_city) As customer_city,
	customer_state
From CleanedCustomers;

-- Erp_geolocation
With CleanedGeography As (
	Select Distinct
		geolocation_zip_code_prefix,
		Round(Avg(Try_Cast(geolocation_lat As Float)) Over(Partition By geolocation_zip_code_prefix), 5) As geolocation_lat,
		Round(Avg(Try_Cast(geolocation_lng As Float)) Over(Partition By geolocation_zip_code_prefix), 5) As geolocation_lng,
		Translate(Replace(Replace(Replace(Replace(Replace(Replace(Lower(Trim(geolocation_city)), '-', ' '), '...', ''), '´', ''), '%26apos%3b', ''''), '³', 'o'), '£', ''),
			'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn') As clean_city,
		Upper(Trim(geolocation_state)) As geolocation_state
	From Bronze.Erp_geolocation
)
Select Distinct
	geolocation_zip_code_prefix,
	geolocation_lat,
	geolocation_lng,
	Silver.Fn_Correct_Known_City(clean_city) As geolocation_city,
	geolocation_state
From CleanedGeography;


