--Mobile Manufacture Data Analysis - ATM



--Q1--List all the states in which we have customers who have bought cellphones from 2005 till today. 
	
	select distinct State from DIM_LOCATION a
	join FACT_TRANSACTIONS b on a.IDLocation = b.IDLocation
	join DIM_DATE c on b.Date = c.DATE
	where YEAR >= 2005


--Q2--What state in the US is buying the most 'Samsung' cell phones?
	
	select top 1 State from DIM_LOCATION a
	join FACT_TRANSACTIONS b on a.IDLocation = b.IDLocation
	join DIM_MODEL c on b.IDModel = c.IDModel
	join DIM_MANUFACTURER d on c.IDManufacturer = d.IDManufacturer
	where Country = 'US' and Manufacturer_Name = 'Samsung' 
	group by state
	order by count(state) desc


--Q3-- Show the number of transactions for each model per zip code per state.       
	
	select c.IDModel, Zipcode, State, Count(quantity)No_of_Transactions from DIM_LOCATION a
	join FACT_TRANSACTIONS b on a.IDLocation = b.IDLocation
	join DIM_MODEL c on b.IDModel = c.IDModel
	group by c.IDModel, ZipCode, State 
	order by c.IDModel, ZipCode, State 

--Q4-- Show the cheapest cellphone

    select top 1 Model_Name, Unit_price from DIM_MODEL 
	order by Unit_price asc

--Q5--Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.

    select top 5 Manufacturer_Name, sum(quantity)Sales_Quantity,  avg(unit_price)Average_Price from DIM_MANUFACTURER a
	join DIM_MODEL b on a.IDManufacturer = b.IDManufacturer
	join FACT_TRANSACTIONS c on b.IDModel = c.IDModel
	group by Manufacturer_Name
	order by avg(unit_price) desc

--Q6-- List the names of the customers and the average amount spent in 2009, where the average is higher than 500
     
	select Customer_Name, avg(totalprice)Average_Price from DIM_CUSTOMER a
	join FACT_TRANSACTIONS b on a.IDCustomer = b.IDCustomer
	where datepart(year,date) = 2009
	group by Customer_Name
	having avg(totalprice) > 500
	
--Q7--  List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010  
	
	select * from
     (select top 5 Model_Name from DIM_MODEL a
	  join FACT_TRANSACTIONS b on a.IDModel = b.IDModel
	  join DIM_DATE c on b.Date = c.DATE
	  where year = 2008
	  group by Model_Name
	  order by sum(quantity) desc

	  intersect

	  select top 5 Model_Name from DIM_MODEL a
	  join FACT_TRANSACTIONS b on a.IDModel = b.IDModel
	  join DIM_DATE c on b.Date = c.DATE
	  where year = 2009
	  group by Model_Name
	  order by sum(quantity) desc
	
	  intersect

	  select top 5 Model_Name from DIM_MODEL a
	  join FACT_TRANSACTIONS b on a.IDModel = b.IDModel
	  join DIM_DATE c on b.Date = c.DATE
	  where year = 2010
	  group by Model_Name
	  order by sum(quantity) desc)T1
	

--Q8--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010. 
    
with cal as (
	select * from dim_date
),
man as (
select x.IDManufacturer as model_manID
		, x.IDModel as model_model_id
		, x.Model_Name as model_model_name
		, x.Unit_price as model_unit_price
		, y.IDManufacturer as manu_manID
		, y.Manufacturer_Name as manufac_name
		from DIM_MODEL x
	join DIM_MANUFACTURER y 
		on y.IDManufacturer = x.IDManufacturer
),
transactions as (
select * from fact_transactions
)
select manufac_name, year  from (
select manufac_name, year, totalprice, row_number() over(partition by year order by manufac_name, year desc) top_n
from transactions a
		join man b
			on a.IDModel = b.model_model_id
		join cal c
			on a.Date = c.Date
) z
where year in (2009, 2010)
and top_n = 2
order by 1,2


--Q9-- Show the manufacturers that sold cellphones in 2010 but did not in 2009.
	
	with cal as (
select * from dim_date
),
man as (
select x.IDManufacturer as model_manID
		, x.IDModel as model_model_id
		, x.Model_Name as model_model_name
		, x.Unit_price as model_unit_price
		, y.IDManufacturer as manu_manID
		, y.Manufacturer_Name as manufac_name
		from DIM_MODEL x
	join DIM_MANUFACTURER y 
		on y.IDManufacturer = x.IDManufacturer
),
transactions as (
select * from fact_transactions
)
select manufac_name, quantity,YEAR
from transactions a
		join man b
			on a.IDModel = b.model_model_id
		join cal c
			on a.Date = c.Date
where year in (2010)
and year not in (2009)
group by manufac_name,Quantity,year
order by manufac_name,Quantity,YEAR


--Q10-- Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend. 
	
select top 100 Customer_Name , year(date) as Year , Avg(Totalprice)Average_Spend, Avg(Quantity)Average_Quantity, 
     lag(Avg(Quantity)) over(order by year(date)) as prev_year_quantity,
		lag(Avg(totalprice)) over(order by year(date)) as prev_year_spend,
		round(((Avg(Quantity) - lag(Avg(Quantity)) over(order by year(date)))/Avg(Quantity))*100,2) as YoY_quantity_change,
		round(((Avg(totalprice) - lag(Avg(totalprice)) over(order by year(date)))/Avg(totalprice))*100,2) as YoY_spend_change
    from DIM_CUSTOMER a
	join FACT_TRANSACTIONS b on a.IDCustomer = b.IDCustomer
	group by Customer_Name, year(date)
	order by avg(totalprice) desc, avg(quantity),YoY_quantity_change, YoY_spend_change desc
