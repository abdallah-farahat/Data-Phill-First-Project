
--Crm_closed_deals

Select
mql_id,
seller_id,
sdr_id,
sr_id,
Format(Cast(won_date As DateTime2), 'dd/MM/yyyy HH:mm:ss')won_date,
Trim(Replace(business_segment,'_',' ')) business_segment,
Trim(Replace(lead_type,'_',' '))lead_type,
Trim(lead_behaviour_profile)lead_behaviour_profile,
has_company,
has_gtin,
Case
	When Trim(average_stock)='unknown'Then Null
	Else Trim(average_stock)
End AS average_stock,
Trim(business_type)business_type,
Cast(Cast(declared_product_catalog_size as Float)As Int)declared_product_catalog_size,
Cast(declared_monthly_revenue As Decimal)declared_monthly_revenue
From Bronze.Crm_closed_deals

--Crm_marketing_qualified_leads

Select
mql_id,
Format(cast(first_contact_date as Date),'dd/MM/yyyy')first_contact_date,
landing_page_id,
Trim(Replace(origin,'_',' '))origin
from Bronze.Crm_marketing_qualified_leads

--Crm_order_reviews

Select
review_id,
order_id,
Cast(review_score As Int) review_score,
review_comment_title,
review_comment_message,
Format(cast(review_creation_date as Date),'dd/MM/yyyy') review_creation_date,
Format(Cast(review_answer_timestamp As DateTime2), 'dd/MM/yyyy HH:mm:ss')review_answer_timestamp
From Bronze.Crm_order_reviews

--Erp_geolocation


With CleanedGeography As (
    Select Distinct 
        geolocation_zip_code_prefix,
        Round(Avg(Cast(geolocation_lat As Float)) Over(Partition By geolocation_zip_code_prefix), 5) As geolocation_lat,
        Round(Avg(Cast(geolocation_lng As Float)) Over(Partition By geolocation_zip_code_prefix), 5) As geolocation_lng,
        Translate(Replace(Replace(Replace(Replace(Replace(Replace(Lower(Trim(geolocation_city)), '-', ' '), '...', ''), '´', ''), '%26apos%3b', ''''), '³', 'o'), '£', ''), 'áàâãäåéèêëíìîïóòôõöúùûüçñ', 'aaaaaaeeeeiiiiooooouuuucn') As clean_city,
        Upper(Trim(geolocation_state)) As geolocation_state
    From Bronze.Erp_geolocation
)
Select Distinct 
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    Case 
        When clean_city Like '% d oeste' Or clean_city Like '% doeste' Then Replace(Replace(clean_city, ' d oeste', ' d''oeste'), ' doeste', ' d''oeste')
        When clean_city Like '% do oeste' Then Replace(clean_city, ' do oeste', ' d''oeste')
        When clean_city Like '% d agua' Or clean_city Like '% dagua' Then Replace(Replace(clean_city, ' d agua', ' d''agua'), ' dagua', ' d''agua')
        When clean_city = 'bh' Then 'belo horizonte'
        When clean_city = 'rj' Then 'rio de janeiro'
        When clean_city = 'sp' Then 'sao paulo'
        When clean_city = 'maceiao' Then 'maceio'
        When clean_city = 'linharesl' Then 'linhares'
        When clean_city = 'mogidascruzes' Then 'mogi das cruzes'
        When clean_city = 'embuguacu' Then 'embu guacu'
        When clean_city = 'saopaulo' Then 'sao paulo'
        When clean_city = '* cidade' Then 'cidade'
        When clean_city = 'vila bela da santssima trindade' Then 'vila bela da santissima trindade'
        When clean_city = 'bacaxa (saquarema)   distrito' Then 'bacaxa'
        When clean_city = 'praia grande (fundao)   distrito' Then 'praia grande'
        When clean_city = 'vitorinos   alto rio doce' Then 'vitorinos'    
        Else clean_city
    End As geolocation_city,
    geolocation_state
From CleanedGeography;

--Erp_order_items

Select
order_id,
Cast(order_item_id As Int)order_item_id,
product_id,
seller_id,
Format(Cast(shipping_limit_date As DateTime2),'dd/MM/yyyy HH:mm:ss')shipping_limit_date,
Cast(price As Float) price,
Cast(freight_value As Float)freight_value
From Bronze.Erp_order_items

--Erp_order_payments

Select
order_id,
Cast(payment_sequential As Int)payment_sequential,
Replace(payment_type,'_',' ')payment_type,
Cast(payment_installments As Int) payment_installments,
Cast(payment_value As Float)payment_value
From Bronze.Erp_order_payments

--Erp_orders

Select
order_id,
customer_id,
order_status,
Format(Cast(order_purchase_timestamp As DateTime2),'dd/MM/yyyy HH:mm:ss')order_purchase_timestamp,
Format(Cast(order_approved_at As DateTime2),'dd/MM/yyyy HH:mm:ss')order_approved_at,
Format(Cast(order_delivered_carrier_date As DateTime2),'dd/MM/yyyy HH:mm:ss')order_delivered_carrier_date,
Format(Cast(order_delivered_customer_date As DateTime2),'dd/MM/yyyy HH:mm:ss')order_delivered_customer_date,
Format(Cast(order_estimated_delivery_date As DateTime2),'dd/MM/yyyy HH:mm:ss')order_estimated_delivery_date
From Bronze.Erp_orders

--Erp_product_category_name_translation

Select
Replace(product_category_name,'_',' ')product_category_name,
Replace(product_category_name_english,'_',' ')product_category_name_english
From Bronze.Erp_product_category_name_translation

--Erp_products

Select
product_id,
Replace(product_category_name,'_',' ')product_category_name,
Cast(Cast(product_name_length As Decimal)As Int)product_name_length,
Cast(Cast(product_description_length As Decimal)As Int)product_description_length,
Cast(Cast(product_photos_qty As Decimal)As Int)product_photos_qty,
Cast(product_weight_g As Float) product_weight_g,
Cast(product_length_cm As Float)product_length_cm,
Cast(product_height_cm As Float) product_height_cm,
Cast(product_width_cm As Float) product_width_cm
From Bronze.Erp_products

--Erp_sellers

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
    Case 
        When raw_clean_city In ('bahia', 'minas gerais', 'santa catarina', 'parana', 'centro', 'unknown', 'vendas@creditparts.com.br') Then 'unknown'  
        When raw_clean_city In ('sp', 'sp / sp', 'sao paluo', 'sao pauo', 'sao paulop', 'sao paulo - sp', 'sao paulo / sao paulo', 'sao paulo sp', 'são paulo','04482255') Then 'sao paulo'
        When raw_clean_city In ('ao bernardo do campo', 'sao bernardo do capo', 'sbc', 'sbc/sp') Then 'sao bernardo do campo'
        When raw_clean_city In ('ribeirao preto / sao paulo', 'ribeirao pretp', 'riberao preto', 'robeirao preto') Then 'ribeirao preto'
        When raw_clean_city In ('rio de janeiro / rio de janeiro', 'rio de janeiro \rio de janeiro', 'angra dos reis rj') Then 'rio de janeiro'
        When raw_clean_city = 'auriflama/sp' Then 'auriflama'
        When raw_clean_city = 'barbacena/ minas gerais' Then 'barbacena'
        When raw_clean_city = 'brasilia df' Then 'brasilia'
        When raw_clean_city = 'carapicuiba / sao paulo' Then 'carapicuiba'
        When raw_clean_city = 'cariacica / es' Then 'cariacica'
        When raw_clean_city = 'lages - sc' Then 'lages'
        When raw_clean_city = 'maua/sao paulo' Then 'maua'
        When raw_clean_city = 'mogi das cruzes / sp' Then 'mogi das cruzes'
        When raw_clean_city = 'pinhais/pr' Then 'pinhais'
        When raw_clean_city = 'santo andre/sao paulo' Then 'santo andre'
        When raw_clean_city = 'sao sebastiao da grama/sp' Then 'sao sebastiao da grama'
        When raw_clean_city = 'belo horizont' Then 'belo horizonte'
        When raw_clean_city = 'cascavael' Then 'cascavel'
        When raw_clean_city = 'floranopolis' Then 'florianopolis'
        When raw_clean_city = 'mogi das cruses' Then 'mogi das cruzes'
        When raw_clean_city = 'portoferreira' Then 'porto ferreira'
        When raw_clean_city = 'tabao da serra' Then 'taboao da serra'
        When raw_clean_city In ('s jose do rio preto', 'sao jose do rio pret') Then 'sao jose do rio preto'
        When raw_clean_city = 'scao jose do rio pardo' Then 'scao jose do rio pardo'
        When raw_clean_city = 'sando andre' Then 'santo andre'
        When raw_clean_city = 'sao jose dos pinhas' Then 'sao jose dos pinhais'
        When raw_clean_city = 'arraial d''ajuda (porto seguro)' Then 'arraial d''ajuda'
        When raw_clean_city = 'andira-pr' Then 'andira'
        When raw_clean_city = 'juzeiro do norte' Then 'juazeiro do norte'
        When raw_clean_city = 'paincandu' Then 'paicandu'
        When raw_clean_city = 'sao miguel d''oeste' Then 'sao miguel do oeste'
        When raw_clean_city In ('santa barbara d oeste', 'santa barbara d´oeste') Then 'santa barbara d''oeste'
    Else Replace(raw_clean_city, '  ', ' ') 
    End As seller_city,
    seller_state
From CleanedSellers

--Crm_customers_dataset      
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
    Case 
        When raw_clean_city In ('bahia', 'minas gerais', 'santa catarina', 'parana', 'centro', 'unknown') Then 'unknown'  
        When raw_clean_city In ('sp', 'sp / sp', 'sao paluo', 'sao pauo', 'sao paulop', 'sao paulo - sp', 'sao paulo / sao paulo', 'sao paulo sp', 'são paulo') Then 'sao paulo'
        When raw_clean_city In ('ao bernardo do campo', 'sao bernardo do capo', 'sbc', 'sbc/sp') Then 'sao bernardo do campo'
        When raw_clean_city In ('ribeirao preto / sao paulo', 'ribeirao pretp', 'riberao preto', 'robeirao preto') Then 'ribeirao preto'
        When raw_clean_city In ('rio de janeiro / rio de janeiro', 'rio de janeiro \rio de janeiro', 'angra dos reis rj') Then 'rio de janeiro'
        When raw_clean_city = 'auriflama/sp' Then 'auriflama'
        When raw_clean_city = 'barbacena/ minas gerais' Then 'barbacena'
        When raw_clean_city = 'brasilia df' Then 'brasilia'
        When raw_clean_city = 'carapicuiba / sao paulo' Then 'carapicuiba'
        When raw_clean_city = 'cariacica / es' Then 'cariacica'
        When raw_clean_city = 'lages - sc' Then 'lages'
        When raw_clean_city = 'maua/sao paulo' Then 'maua'
        When raw_clean_city = 'mogi das cruzes / sp' Then 'mogi das cruzes'
        When raw_clean_city = 'pinhais/pr' Then 'pinhais'
        When raw_clean_city = 'santo andre/sao paulo' Then 'santo andre'
        When raw_clean_city = 'sao sebastiao da grama/sp' Then 'sao sebastiao da grama'
        When raw_clean_city = 'belo horizont' Then 'belo horizonte'
        When raw_clean_city = 'cascavael' Then 'cascavel'
        When raw_clean_city = 'floranopolis' Then 'florianopolis'
        When raw_clean_city = 'mogi das cruses' Then 'mogi das cruzes'
        When raw_clean_city = 'portoferreira' Then 'porto ferreira'
        When raw_clean_city = 'tabao da serra' Then 'taboao da serra'
        When raw_clean_city In ('s jose do rio preto', 'sao jose do rio pret') Then 'sao jose do rio preto'
        When raw_clean_city = 'scao jose do rio pardo' Then 'scao jose do rio pardo'
        When raw_clean_city = 'sando andre' Then 'santo andre'
        When raw_clean_city = 'sao jose dos pinhas' Then 'sao jose dos pinhais'
        When raw_clean_city = 'arraial d''ajuda (porto seguro)' Then 'arraial d''ajuda'
        When raw_clean_city = 'andira-pr' Then 'andira'
        When raw_clean_city = 'juzeiro do norte' Then 'juazeiro do norte'
        When raw_clean_city = 'paincandu' Then 'paicandu'
        When raw_clean_city = 'sao miguel d''oeste' Then 'sao miguel do oeste'
        When raw_clean_city In ('santa barbara d oeste', 'santa barbara d´oeste') Then 'santa barbara d''oeste'
    Else Replace(raw_clean_city, '  ', ' ') 
    End As customer_city,
    customer_state
From CleanedCustomers;