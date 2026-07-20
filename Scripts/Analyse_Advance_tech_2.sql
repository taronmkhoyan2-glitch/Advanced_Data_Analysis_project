-----Part to whole analysis
--Analyze how an individual part is performing compared to the overall,
--allowing us to understand which category has the greatest impact on the business.
--Fromula ([mesure]/Total[measure])*100 by [Dimension]
--        (sales/total Sales)*100 by category
--        (quantity/Total Qunatity)*100 by country 

----------------------------------------------------------------------------------------


--Task
--which categories contribute the most to overall sales ?

with 
	category_sales as (
	select 
	p.category,
	sum(f.sales_amount) as total_sales
	from gold.fact_sales f
	left join gold.dim_products p
	on f.product_key=p.product_key
	group by category)
select
category,
total_sales,
sum(total_sales) over () as overall_sales,
concat(round((cast(total_sales as float)/sum(total_sales) over ())*100,2), '%') as percentage_of_total

from category_sales
order by total_sales desc
go


-------Data Segmentation
--Group the data based on a specific range
--Helps to understand the corelation between two measures
--[Measure] by [Measure]
--total products by sales range
--total customers by age
---------------------------------------------------------------------------------------------------------
--Task 1
--Segment products to cost ranges and count how many products fall into each segment
with products_segments as (
	select
	product_key,
	product_name,
	cost,
	case when cost<100 then 'below 100'
		 when cost between 100 and 500 then '100-500'
		 when cost between 500 and 1000 then '500-1000'
		 else 'above 1000'
	end cost_range
	from gold.dim_products)
select
cost_range,
count(product_key) as total_products
from products_segments
group by cost_range
order by total_products desc
go
----------------------------------------------------------------------------------------
---Task 2
/* Group customers into three segments based on their spending behavior:
--VIP: Customers with at least 12 monts of history and spending more than 5000.
--Regular: Customers with at least 12 months of history but spending 5000 or less.
--New: Custoemrs with a lifespan less than 12 months.
ANd find the total number of custoers by each group */



--Option 1
with customer_spending as (
	select 
	c.customer_key,
	sum(f.sales_amount) as total_spending,
	min(order_date) as first_order,
	max(order_date) as last_order,
	DATEDIFF(month,min(order_date) ,max(order_date) ) as lifespan
	from gold.fact_sales f
	left join gold.dim_customers c
	on f.customer_key=c.customer_key
	group by c.customer_key)
Select
case when lifespan>=12 and total_spending>5000 then 'vip'
     when lifespan>=12 and total_spending<=5000 then 'regular'
	 else 'New'
end customer_segment,
count (customer_key) as total_customers
from customer_spending
group by 
case when lifespan>12 and total_spending>5000 then 'vip'
     when lifespan>12 and total_spending<=5000 then 'regular'
	 else 'New'
end
go

--Option 2
with customer_spending as (
	select 
	c.customer_key,
	sum(f.sales_amount) as total_spending,
	min(order_date) as first_order,
	max(order_date) as last_order,
	DATEDIFF(month,min(order_date) ,max(order_date) ) as lifespan
	from gold.fact_sales f
	left join gold.dim_customers c
	on f.customer_key=c.customer_key
	group by c.customer_key)
select
customer_segment,
count(customer_key) as total_customers
from (
		Select
		customer_key,
		case when lifespan>=12 and total_spending>5000 then 'vip'
			 when lifespan>=12 and total_spending<=5000 then 'regular'
			 else 'New'
		end customer_segment

		from customer_spending) t
group by customer_segment
order by total_customers desc
go




