SELECT 
    SUM(price + freight_value) AS Total_Revenue,
    COUNT(DISTINCT order_id) AS Total_Orders,
    SUM(price + freight_value) / COUNT(DISTINCT order_id) AS Average_Order_Value
FROM Gold.Fact_Order_Items
WHERE Is_Revenue_Eligible = 1;

SELECT 
    AVG(CAST(review_score AS DECIMAL(3,2))) AS Average_Review_Score
FROM Gold.Fact_Reviews;


SELECT TOP 7
    dp.Category_Name_En, 
    SUM(foi.price + foi.freight_value) AS Revenue 
FROM Gold.Fact_Order_Items foi 
JOIN Gold.Dim_Product dp ON foi.Product_Key = dp.Product_Key 
WHERE foi.Is_Revenue_Eligible = 1
GROUP BY dp.Category_Name_En 
ORDER BY Revenue DESC;

SELECT 
    dd.Year_Number, 
    SUM(foi.price + foi.freight_value) AS Revenue 
FROM Gold.Fact_Order_Items foi 
JOIN Gold.Dim_Date dd ON foi.Purchase_Date_Key = dd.Date_Key 
WHERE foi.Is_Revenue_Eligible = 1
GROUP BY dd.Year_Number 
ORDER BY dd.Year_Number;


SELECT 
    payment_type, 
    COUNT(payment_sequential) AS Payment_Count,
    SUM(payment_value) AS Total_Payment_Value
FROM Gold.Fact_Payments 
GROUP BY payment_type
ORDER BY Total_Payment_Value DESC;

SELECT 
    review_score, 
    COUNT(review_id) AS Ratings_Count 
FROM Gold.Fact_Reviews 
GROUP BY review_score 
ORDER BY review_score ASC;