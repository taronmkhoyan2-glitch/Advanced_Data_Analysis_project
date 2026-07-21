/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

create view gold.report_products as



with base_query as (--Base query showing main data columns from tables
	select
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quanity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
	from gold.fact_sales f
	left join gold.dim_products p
	on f.product_key=p.product_key
	where order_date is not null ),

product_aggregations as (--Product Aggregations: Summarizes key metrics at the product level
	select
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	datediff(month,min(order_date),max(order_date)) as lifespan,
	max(order_date) as last_sale_date,
	count(distinct order_number) as total_orders,
	count(distinct customer_key) as Total_customers,
	sum(sales_amount) as total_sales,
	sum(quanity) as total_quantity,
	round(avg(cast(sales_amount as float)/nullif(quanity,0)),1) as avg_selling_price
	from base_query
	group by 
	 product_key,
	product_name,
	category,
	subcategory,
	cost
	)

Select      --Final Query: Combines all product results into one output
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
datediff(month,last_sale_date,getdate()) as recency_in_months,
case 
    when total_sales>50000 then 'High_performer'
	when total_sales >=10000 then 'Mid-Range'
	else 'low-performer'
end as product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
case   --Average Order Revenue (AOR)
    when total_orders=0 then 0
	else total_sales/total_orders
end as avg_order_revenue,
case   ---- Average Monthly Revenue
    when lifespan=0 then total_sales
	else total_sales/lifespan
end as avg_monthly_revenue

from product_aggregations
go


