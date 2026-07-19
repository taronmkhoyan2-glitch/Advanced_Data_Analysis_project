
------Trend Analysing (Change over time)
--Sum[Measure] by [Date dimension]
--Exc. Total sales by Year

Use DataWarehouse
go
--We going to use views in gold layer

--Task
-----------------------------
--Analyse Sales over time



--Year option
select
year(order_date) as order_year,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quanity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date)
order by year(order_date)
go


--Month option
select
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quanity) as total_quantity
from gold.fact_sales
where order_date is not null
group by month(order_date)
order by month(order_date)
go


--Month and Year
select
year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quanity) as total_quantity
from gold.fact_sales
where order_date is not null
group by year(order_date),month(order_date)
order by year(order_date),month(order_date)
go



--Month and Year Using datetrunc
select
datetrunc(month,order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_key) as total_customers,
sum(quanity) as total_quantity
from gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
order by datetrunc(month,order_date)
go


------Cumulative Analysis
--Agregate the data progressively over time
--Sum[Cumulative Measure] by [date dimensiom]
-- EXample Runing total
-----------Moving average
-------------------------------------------------------------------------

--Tasks
--Calculate the total Sales per month
--and the runing total of sales over time


select
order_date,
total_sales,
sum(total_sales) over (order by order_date ) as running_total_sales,
avg(avg_price) over (order by order_date) as moving_avgerage_price
from (
	select
	datetrunc(month,order_date) as order_date,
	Sum(sales_amount) as total_sales,
	avg(price) as avg_price
	from gold.fact_sales
	where order_date is not null
	group by datetrunc(month,order_date)
) t
go

----Performance Analysis
--diference between current[Mesure]-Target[measure]
-------------------------------------------------------------------------
--task
/* Analyze the yearly performance of products by comparing their sales
to both the average sales performance of the product and the previous year's sales */
-------------------------------------------------------------------------------------------------


With yearly_product_sales as(

	select
	p.product_name,
	year(order_date) as order_year,
	sum(sales_amount) as current_sales

	from gold.fact_sales f
	left join gold.dim_products p
	on f.product_key=p.product_key
	where order_date is not null
	group by product_name,year(order_date)
	
	) 
select 
order_year,
product_name,
current_sales,
avg(current_sales) over (partition by product_name) as avg_sales,
current_sales-avg(current_sales) over (partition by product_name) as diff_avg,
case when current_sales-avg(current_sales) over (partition by product_name)>0 then 'Above Avg'
     when current_sales-avg(current_sales) over (partition by product_name)<0 then 'Below Avg'
	 else 'avg'
end avg_change,
lag(current_sales) over (partition by product_name order by order_year) as previous,
current_sales-lag(current_sales) over (partition by product_name order by order_year) as diff_py,
case when current_sales-lag(current_sales) over (partition by product_name order by order_year)>0 then 'Increase'
     when current_sales-lag(current_sales) over (partition by product_name order by order_year)<0 then 'Deacrease'
	 else 'No Change'
end py_change

from yearly_product_sales
order by product_name,order_year
go
