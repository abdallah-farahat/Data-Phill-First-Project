/*
----------------------------------------------------------------------------
   1. YEAR-OVER-YEAR REVENUE GROWTH BY PRODUCT CATEGORY
---------------------------------------------------------------------------- 
*/
With Yearly_Revenue As (
    Select
        p.Category_Name_En  product_category,
        d.Year_Number order_year,
        Sum(oi.price + oi.freight_value) total_revenue
    From Gold.Fact_Order_Items oi
    Join Gold.Fact_Orders o On oi.order_id         = o.order_id
    Join Gold.Dim_Date    d On o.Purchase_Date_Key = d.Date_Key
    Join Gold.Dim_Product  p On oi.Product_Key     = p.Product_Key
    Where o.order_status = 'delivered'
    Group By  p.Category_Name_En, d.Year_Number
),
Calculated_Growth As (
    Select
        product_category,
        order_year,
        total_revenue,
        Coalesce(Cast(Lag(total_revenue) Over (Partition By product_category Order By order_year)As Float), 0) As prev_year_revenue
    From Yearly_Revenue
)
Select
    product_category,
    order_year,
    total_revenue,
    prev_year_revenue,
    Case 
        When prev_year_revenue = 0 then '0%'
        Else CONCAT(ROUND(CAST(((total_revenue - prev_year_revenue) / prev_year_revenue) * 100 AS FLOAT), 2),'%')
    End As yoy_growth_pct
From Calculated_Growth
Where product_category Is Not Null
Order BY product_category, order_year;
/*
----------------------------------------------------------------------------
   2. RUNNING TOTAL & 3-MONTH MOVING AVERAGE OF MONTHLY REVENUE
----------------------------------------------------------------------------
*/
With Monthly_Revenue As (
    Select
        d.Year_Number  As order_year,
        d.Month_Name As Month_Name,
        d.Month_Number As Month_Number,
        Sum(oi.price + oi.freight_value) As monthly_total
    From Gold.Fact_Order_Items oi
    Join Gold.Fact_Orders o On oi.order_id = o.order_id
    Join Gold.Dim_Date    d On o.Purchase_Date_Key = d.Date_Key
    Where o.order_status = 'delivered'
    Group By d.Year_Number, d.Month_Name,d.Month_Number
)
Select
    order_year,
    Month_Name,
    monthly_total,
    Sum(monthly_total) Over (Order By order_year, Month_Name Rows Between Unbounded Preceding And Current Row)  running_total,
    Cast(Round(Avg(monthly_total) Over (Order By order_year, Month_Name Rows Between 2 Preceding And Current Row),2)As Float) moving_avg_3mo
From Monthly_Revenue
Order BY order_year,Month_Number ;
/*
----------------------------------------------------------------------------
   3. CUSTOMER RFM SEGMENTATION (Recency, Frequency, Monetary)
----------------------------------------------------------------------------
*/
With RFM_Base As (
    Select
        c.Customer_Key,
        DateDiff(Day, Max(d.Full_Date), '2018-10-17')  recency_days,
        Count(Distinct o.order_id)frequency,
        Sum(oi.price)monetary
    From Gold.Fact_Orders o
    Join Gold.Dim_Customer c  On o.Customer_Key = c.Customer_Key
    Join Gold.Dim_Date d  On o.Purchase_Date_Key = d.Date_Key
    Join Gold.Fact_Order_Items oi ON oi.order_id = o.order_id
    Where o.order_status = 'delivered'
    Group By c.Customer_Key
),
RFM_Scored As (
    Select
        Customer_Key,
        recency_days, frequency, monetary,
        Ntile(5) Over(Order By recency_days Desc)r_score,
        Ntile(5) Over(Order By frequency)f_score,
        Ntile(5) Over(Order By monetary)m_score
    From RFM_Base
)
Select
    *,
    Case
        When r_score >= 4 AND f_score >= 4 AND m_score >= 4 Then 'Champions'
        When r_score >= 4 AND f_score <= 2 Then 'New Customers'
        When r_score <= 2 AND f_score >= 4 AND m_score >= 4 Then 'At Risk (High Value)'
        When r_score <= 2 AND f_score <= 2 Then 'Lost / Churned'
        Else 'Regular'
    End As customer_segment
From RFM_Scored
Order BY m_score Desc, f_score Desc;
 
/*
----------------------------------------------------------------------------
   4. AVERAGE REVIEW SCORE vs. DELIVERY DELAY (CORRELATION-STYLE ANALYSIS)
     
----------------------------------------------------------------------------
*/
Select 
    Case
        when delivery_delay_days <= 0 Then 'On time / early'
        when delivery_delay_days BETWEEN 1 AND 5   Then '1-5 days late'
        when delivery_delay_days BETWEEN 6 AND 15  Then '6-15 days late'
        Else '15+ days late'
    End As  delay_bucket,
    Round(Avg(Cast(r.review_score As Float)),2)  avg_review_score,
    Count(*)order_count
From Gold.Fact_Orders o
Join Gold.Fact_Reviews r       On r.order_id = o.order_id
Join Gold.Dim_Date d_delivered On o.Delivered_Date_Key           = d_delivered.Date_Key
Join Gold.Dim_Date d_estimated On o.Estimated_Delivery_Date_Key  = d_estimated.Date_Key
Cross Apply (
    Select Datediff(Day, d_estimated.Full_Date, d_delivered.Full_Date) delivery_delay_days
) delay
Where o.order_status = 'delivered'
Group By
    Case
        when delivery_delay_days <= 0 Then 'On time / early'
        when delivery_delay_days Between 1 And 5 Then '1-5 days late'
        when delivery_delay_days Between 6 And 15 Then '6-15 days late'
        Else '15+ days late'
    End
Order By avg_review_score Desc;
