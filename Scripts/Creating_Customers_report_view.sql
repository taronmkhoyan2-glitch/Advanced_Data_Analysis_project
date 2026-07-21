/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================



------------------------------------------------------------------------------------
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

create view gold.report_customers as
with base_query as ( --1)Base Quesry: Retrive core columns from tables
	select
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quanity,
	c.customer_key,
	c.customer_number,
	concat(c.first_name,' ',c.last_name) as customer_name,
	DATEDIFF(year,birthdate,GETDATE()) as age
	from gold.fact_sales f
	left join gold.dim_customers c
	on f.customer_key=c.customer_key
	where order_date is not null )
  
  ,customer_aggregation as( --2)Second Query for agregation
		select
		customer_key,
		customer_number,
		customer_name,
		age,
		count(distinct order_number) as total_orders,
		sum(sales_amount) as total_sales,
		sum(quanity) as total_quantity,
		count(distinct product_key) as total_produts,
		max(order_date) as last_order_date,
		DATEDIFF(month,min(order_date),max(order_date)) as lifespan
		from base_query
		group by
		customer_key,
		customer_number,
		customer_name,
		age )
select
customer_key,
customer_number,
customer_name,
age,
case when age<20 then 'under 20'
     when age between 20 and 29 then '20-29'
	 when age between 30 and 39 then '30-39'
	 when age between 40 and 49 then '40-49'
	 else '50 and above'
end as age_group,
CASE 
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'New'
END AS customer_segment,
last_order_date,
DATEDIFF(month,last_order_date,getdate()) as recency ,
total_orders,
total_sales,
total_quantity,
total_produts,
lifespan,
--Compute average order value(avo)
case when total_orders=0 then 0
     else total_sales/total_orders
end as avg_order_value,
--Compute average monthly spend
case when lifespan=0 then total_sales
     else total_sales/lifespan
end as avg_monthly_spend
from customer_aggregation
go


--Examples of advantage of having report
select
age_group,
count(customer_number) as total_customers,
sum(total_sales) as total_sales
from gold.report_customers
group by age_group
go
----------------------------------------------------
select
customer_segment,
count(customer_number) as total_customers,
sum(total_sales) as total_sales
from gold.report_customers
group by customer_segment
go


