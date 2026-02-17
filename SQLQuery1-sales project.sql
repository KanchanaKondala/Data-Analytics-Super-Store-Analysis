create table sales_store(
transaction_id varchar(50),	customer_id varchar(50),
customer_name nvarchar(100),
customer_age int,	gender varchar(20),
product_id varchar(50),	product_name nvarchar(50),	
product_category varchar(50),	quantiy int,	prce float,
payment_mode varchar(50),	purchase_date date,	
time_of_purchase TIME,	status varchar(50));

------bulk data insert file----------
SET DATEFORMAT dmy
BULK INSERT sales_store from 'C:\Users\eswar\Downloads\sale.csv' with (FIRSTROW=2,
FIELDTERMINATOR=',',ROWTERMINATOR='\n');

-----date cleaning---
select * from sales_store;
---copy the same table to get not effected by any changes while cleaning---
select * into sales from sales_store;
select * from sales;
----STEP 1----check for duplicate---
select TRANSACTION_ID, count(*) from sales 
group by transaction_id having count(*)>1;

---to remvoe 4 duplicate values----

with CTE AS(
select *,
row_number() over (partition by transaction_id order by transaction_id)
as row_num from sales)
---Delete from CTE where row_num=2;
select * from CTE where transaction_id in('TXN240646',
'TXN342128',	
'TXN855235',	
'TXN981773');
----step 2-------Correction of Headers------
exec sp_rename 'sales.quantiy','quantity','COLUMN'
exec sp_rename'sales.prce','price','COLUMN'

-----Check data type-------
select column_name,data_type from information_schema.columns
where table_name='sales'

-----check NULL values------
-----null count--------
select * from sales where transaction_id is null or	
customer_id is null or	customer_name is null or
customer_age is null or	gender is null or
product_id is null or	product_name is null or	product_category is null or
quantity is null or	price is null or	payment_mode is null or
purchase_date is null or	time_of_purchase is null 
or	status is null;

Delete from sales where transaction_id  is null;
select * from sales;
select * from sales where customer_name='Damini Raju';
update sales set customer_id='CUST1401' 
where transaction_id='TXN985663';
select * from sales where customer_id='CUST1003';

update sales set customer_name='Mahika Saini',customer_age=35,
gender='Male'
where transaction_id='TXN432798';

select * from sales where customer_name='Ehsaan Ram';
update sales set customer_id='CUST9494' 
where transaction_id='TXN977900';


------ step 5 data cleaning-------
select distinct gender from sales;
select product_category gender from sales;
select distinct product_category gender from sales;
update sales set gender='M' where gender='Male';
update sales set gender='F' where gender='Female';
select * from sales;
select distinct payment_mode from sales;
update sales set payment_mode='Credit Card' where payment_mode='CC';
update sales set payment_mode='Debit Card' where payment_mode='DC';



select gender,sum(quantity) as gender_quantity from sales 
group by gender 
order by gender_quantity asc

-----DATA ANALYSIS------------------------------------------------------------
--1. TOP 5 most selling products by quantity-------
select top 5 product_name,sum(quantity) as total_selling_product from sales 
group by product_name order by sum(quantity) desc;
---note: Here we need only sucessfull products,
--so we check teh stuts deliverd-----
select top 5 product_name,sum(quantity) as total_selling_product from sales 
where status='delivered'
group by product_name order by sum(quantity) desc;

---which products are mostly canceled---
select distinct status from sales;
select top 5 product_name,count(*) as cancel_products from sales 
where status='cancelled' group by product_name order by cancel_products desc; 

---3.what time of the day has the highest purchases?----
select * from sales;
select case 
when DATEPART(Hour,time_of_purchase) between 0 and 5 then 'night'
when DATEPART(Hour,time_of_purchase) between 6 and 11 then 'morning'
when DATEPART(Hour,time_of_purchase) between 12 and 17 then 'afternoon'
when DATEPART(Hour,time_of_purchase) between 18 and 23 then 'evening'
end as time_of_day,count(*) as total_orders from sales
group by 
case 
when DATEPART(Hour,time_of_purchase) between 0 and 5 then 'night'
when DATEPART(Hour,time_of_purchase) between 6 and 11 then 'morning'
when DATEPART(Hour,time_of_purchase) between 12 and 17 then 'afternoon'
when DATEPART(Hour,time_of_purchase) between 18 and 23 then 'evening'
end
order by total_orders desc;

---4. who are the top 5 highest spending customers--
select * FROM sales;
select top 5 customer_name, format(sum(price*quantity),'c0','en-IN')as highest_spend from sales
group by customer_name order by sum(price*quantity) desc;


----5.which product categories generates the highest revenue-------------

select product_category,format(sum(quantity*price),'C0','en-IN')as Revenue from sales
group by product_category order by sum(quantity*price) desc;

-----6.whhat is the return and cancellation rate per category-----

----cancellation------
select distinct status from sales;

select product_category,
format(count(case when status='cancelled'then 1 end)*100.0/count(*),'N3')+'%' AS cancel_rate
from sales
group by product_category
order by cancel_rate desc;

----RETURN-----
select product_category,
format(count(case when status='returned' then 1 end)*100.0/count(*),'N3')+'%' AS return_rate
from sales
group by product_category
order by return_rate desc

------
select product_category,
format(count(case when status='returned' then 1 end)*100.0/count(*),'N3')+
'%'AS return_rate
from sales
group by product_category
order by return_rate desc

----7th. what is the most preferred payment mode------
select * from sales;
select distinct payment_mode from sales;
select payment_mode, count(*) as most_payment from sales
group by payment_mode
order by most_payment desc;

----8. how does age group affect purchaing behaviour-----
select
case
	when customer_age between 18 and 25 then '18-25'
	when customer_age between 26 and 35 then '26-35'
	when customer_age between 36 and 50 then '36-50'
	else '51+'
	end as customer_age,
	format(sum(price*quantity),'c0','en-In')as purchase_mode
	from sales

group by case
	when customer_age between 18 and 25 then '18-25'
	when customer_age between 26 and 35 then '26-35'
	when customer_age between 36 and 50 then '36-50'
	else '51+'
	end
	
order by purchase_mode desc;

---9. what is the monthly sales trend------
select * from sales;

select 
---year(purchase_date)as years,
month(purchase_date) as months,
format(sum(price*quantity),'c0','en-In') as total_sales,
sum(quantity) as total_quantity
from sales
group by month(purchase_date)
order by months;

--10.Are certain genders buying more specific product catagories---
select distinct gender from sales;

select * from (select gender,product_category from sales)
as source_table
pivot(
count(gender)
for gender in ([M],[F])
)
as pivot_table
order by product_category;
-----Method 2-----

SELECT 
    product_category,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS Male,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS Female
FROM sales
GROUP BY product_category
ORDER BY product_category;

-----done------

























































































 