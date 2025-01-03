SELECT * FROM gdb023.dim_customer;
select * from dim_product;
#1Provide the list of markets in which customer "Atliq Exclusive" operates its
#business in the APAC region.
Select distinct market 
from dim_customer
 where customer = 'Atliq Exclusive' and region = 'APAC';
 ##2What is the percentage of unique product increase in 2021 vs. 2020? The
#final output contains these fields,unique_products_2020, unique_products_2021, percentage_chg
select * from fact_sales_monthly;
SELECT 
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END) AS unique_products_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) AS unique_products_2021,
    ROUND(
        (COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product_code END) - 
         COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)) * 100.0 / 
         COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product_code END)
        , 2) AS percentage_chg
FROM 
  fact_sales_monthly
WHERE 
    fiscal_year IN (2020, 2021);
#3Provide a report with all the unique product counts for each segment and
#sort them in descending order of product counts. The final output contains
#, segment product_count
select segment, COUNT(DISTINCT PRODUCT) AS UNIQUE_PRODUCTCOUNT from dim_product
Group by segment
ORDER BY unique_productcount DESC;
#4 4. Follow-up: Which segment had the most increase in unique products in
#2021 vs 2020? The final output contains these fields,
#segment, product_count_2020, product_count_2021, difference
#dimproduct and #fact_sales monthly
select segment,  COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product END) AS product_count_2020,
    COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product END) AS product_count_2021,
   ( COUNT(DISTINCT CASE WHEN fiscal_year = 2021 THEN product END)  -
    COUNT(DISTINCT CASE WHEN fiscal_year = 2020 THEN product END)) AS DIFFERENCE from dim_product p join fact_sales_monthly fsm on fsm.product_code = p.product_code
    Group by segment
    order by difference desc
    LIMIT 1
# Get the products that have the highest and lowest manufacturing costs.
#The final output should contain these fields,
#product_code, product, manufacturing_cost
#concepts like joins, where, min, max, sub-queries
-- Query to get both highest and lowest manufacturing cost products
Select * from dim_product;
select * from fact_manufacturing_cost
Select dp. product_code, dp.product, fmc.manufacturing_cost 
FROM dim_product dp left join 
fact_manufacturing_cost fmc 
on fmc.product_code = dp.product_code
Where fmc.manufacturing_cost = (select max(manufacturing_cost) FROM fact_manufacturing_cost fmc)
UNION
Select dp. product_code, dp.product, fmc.manufacturing_cost 
FROM dim_product dp RIGHT JOIN
fact_manufacturing_cost fmc 
on fmc.product_code = dp.product_code
Where fmc.manufacturing_cost = (select min(manufacturing_cost) FROM fact_manufacturing_cost fmc)
#6 Generate a report which contains the top 5 customers who received an
#average high pre_invoice_discount_pct for the fiscal year 2021 and in the
#Indian market. The final output contains these fields, customer_code, customer
#average_discount_percentage
#fact_pre_invoice_deductions and dim_customer
Select * from dim_customer;
select * from fact_pre_invoice_deductions;
With discount_percentage as (
select dc.customer_code, dc.customer, round(avg(pre_invoice_discount_pct),2) as avgpreinvoiced
 FROM dim_customer dc JOIN fact_pre_invoice_deductions fpid
 ON fpid.customer_code = dc.customer_code
 where fiscal_year = '2021' and Market = 'India'
 GROUP BY customer_code, Customer )
 Select customer_code, customer, avgpreinvoiced 
 FROM discount_percentage 
 ORDER BY avgpreinvoiced desc
 LIMIT 5
 #7. Get the complete report of the Gross sales amount for the customer “Atliq
#Exclusive” for each month. This analysis helps to get an idea of low and
#high-performing months and take strategic decisions.
#The final report contains these columns: Month, Year, Gross sales Amount#
 Select * from fact_sales_monthly;
 select * from dim_customer;
 select * from fact_gross_price;
 SELECT 
    MONTH(fsm.date) AS Month,
    YEAR(fsm.date) AS Year,
    ROUND(SUM(fsm.Sold_Quantity * fgp.Gross_Price), 2) AS Gross_Sales_Amount
FROM 
    Fact_Sales_Monthly fsm
JOIN 
    Dim_Customer dc ON fsm.Customer_Code = dc.Customer_Code
JOIN 
    Fact_Gross_Price fgp ON fsm.Product_Code = fgp.Product_Code
        AND fsm.Fiscal_Year = fgp.Fiscal_Year
WHERE 
    dc.Customer = 'Atliq Exclusive'
GROUP BY 
    YEAR(fsm.Date), MONTH(fsm.Date)
ORDER BY 
    Year, Month;
#8. In which quarter of 2020, got the maximum total_sold_quantity? The final
#Quarter, total_sold_quantity
# use the fact_sales_monthly table
# derive the Month from the date and assign a Quarter. Note that fiscal_year
#for Atliq Hardware starts from September(09)
#concepts like CTEs, case-when, where, Group by, Order by, and
#Aggregate function(sum).
WITH Sales_With_Quarter AS (
    SELECT 
        CASE 
            WHEN MONTH(fsm.date) IN (9, 10, 11) THEN 'Q1'
            WHEN MONTH(fsm.date) IN (12, 1, 2) THEN 'Q2'
            WHEN MONTH(fsm.date) IN (3, 4, 5) THEN 'Q3'
            ELSE 'Q4'
        END AS Quarter,
        SUM(fsm.sold_quantity) AS total_sold_quantity
    FROM 
        fact_sales_monthly fsm
    WHERE 
        fsm.fiscal_year = '2020'
    GROUP BY 
        CASE 
            WHEN MONTH(fsm.date) IN (9, 10, 11) THEN 'Q1'
            WHEN MONTH(fsm.date) IN (12, 1, 2) THEN 'Q2'
            WHEN MONTH(fsm.date) IN (3, 4, 5) THEN 'Q3'
            ELSE 'Q4'
        END
)
SELECT 
    Quarter,
    total_sold_quantity
FROM 
    Sales_With_Quarter
ORDER BY 
    total_sold_quantity DESC
LIMIT 1;
#Which channel helped to bring more gross sales in the fiscal year 2021
#and the percentage of contribution? The final output contains these fields,
#channel, gross_sales_mln, percentage
#1. gross_sales_mln = gross_price * sold_quantity
#2. use fact_sales_monthly, fact_gross_price, dim_customer tables
#3. concepts like joins, CTEs, where, Group by, Aggregate function(sum),
#Round, order by, Limit, and window functions
WITH Sales_CTE AS (
    SELECT 
        dc.Channel, 
        SUM(fsm.Sold_Quantity * fgp.Gross_Price) AS total_gross_sales
    FROM 
        fact_sales_monthly fsm
    JOIN 
        dim_customer dc ON fsm.Customer_Code = dc.Customer_Code
    JOIN 
        fact_gross_price fgp ON fsm.Product_Code = fgp.Product_Code
        AND fsm.Fiscal_Year = fgp.Fiscal_Year
    WHERE 
        fsm.Fiscal_Year = '2021'
    GROUP BY 
        dc.Channel
)
SELECT 
    sc.Channel,
    ROUND(sc.total_gross_sales / 1000000, 2) AS gross_sales_mln,
    ROUND(100 * sc.total_gross_sales / SUM(sc.total_gross_sales) OVER (), 2) AS percentage
FROM 
    Sales_CTE sc
ORDER BY 
    sc.total_gross_sales DESC
LIMIT 1;
select * from fact_gross_price
#10. Get the Top 3 products in each division that have a high
#total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields,division, product_code, product, total_sold_quantity, rank_order
#use fact_sales_monthly, dim_product tables
#concepts like CTEs, filtering, Group by, Aggregate function(sum), window
#functions like Rank, Partition By
WITH totalsoldq AS (
    SELECT 
        p.Division, 
        p.Product_Code, 
        p.Product, 
        SUM(s.Sold_Quantity) AS total_sold_quantity
    FROM 
        fact_sales_monthly s
    JOIN 
        dim_product p ON s.Product_Code = p.Product_Code
    WHERE 
        s.Fiscal_Year = 2021
    GROUP BY 
        p.Division, p.Product_Code, p.Product
),
Ranking AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY Division ORDER BY total_sold_quantity DESC) AS rank_order
    FROM 
        totalsoldq
)
SELECT 
   *
FROM 
    Ranking
WHERE 
    rank_order <= 3
ORDER BY 
    Division, rank_order;

 




 

