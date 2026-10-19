CREATE VIEW gold.report_customer as
with base_query as (
/* 
-----------------------------------------------
Base query : retrieves core columns from tables
-----------------------------------------------
*/ 
SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    DATEDIFF(year, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL 
)


, customer_aggregation as (
/* --------------------------------------------------------------------
2/customer_aggregation : summarizes key metrics at the customer level ,
-----------------------------------------------------------------------
*/
select 
customer_key,
customer_number,
customer_name,
age,

count(distinct order_number)as total_order,
sum(sales_amount) as total_sales,
sum(quantity) as totla_quantity,
count(product_key) as total_product,
max(order_date) as last_order,
DATEDIFF(month,min(order_date),max(order_date)) as lifespan
from base_query
group by customer_key,
customer_number,
customer_name,
age
)


select
customer_key,
customer_number,
customer_name,
age,
total_order,
total_sales,
totla_quantity,
total_product,
last_order,
DATEDIFF(month,last_order,GETDATE()) as recency,
case  when age<20 then 'above 50'
      when age between 20 and 29 then '20-29'
      when age between 30 and 39 then '30-39'
      when age between 40 and 49 then '40-49'
      else 'above 50'
end age_segmentation ,

case when lifespan>= 12 and total_sales>=5000  then 'VIP'
       when lifespan >= 12 and total_sales<5000 then 'regular'
       else 'new'
end customer_segment,
-- compuate average order value 
case when total_sales = 0 then 0
     else total_sales/total_order 
end avg_order_value,
--compute average monthly spend 
case when lifespan = 0 then total_sales 
     else total_sales/lifespan 
end avg_monthly_spend
from customer_aggregation


