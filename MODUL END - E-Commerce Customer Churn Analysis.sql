
CREATE DATABASE ecomm;
USE ecomm;
select*from customer_churn;

------------------------------------------------------------------------------
-- DATA CLEANIG --
------------------------------------------------------------------------------
--   Handling Missing Values and Outliers: --
--   Impute mean  for the following columns, and round off to the nearest integer --

set sql_safe_updates=0;

        -- Warehousetohome --
update customer_churn
set WarehouseToHome = (select round(AVG(WarehouseToHome)) 
from(select*from customer_churn ) as round)
where WarehouseToHome is null ;
  
       -- Hourspendonapp --
update customer_churn
set HourSpendOnApp = (select round(AVG(HourSpendOnApp)) 
from(select*from customer_churn ) as round)
where HourSpendOnApp is null ;  
  
       -- Orderamounthikefromlastyear --
 update customer_churn
set  OrderAmountHikeFromLastYear  = (select round(AVG(OrderAmountHikeFromLastYear )) 
from(select*from customer_churn ) as round)
where OrderAmountHikeFromLastYear  is null ;  
 
       -- Daysincelastorder --
  update customer_churn
set DaySinceLastOrder = (select round(AVG( DaySinceLastOrder)) 
from(select*from customer_churn ) as round)
where DaySinceLastOrder is null ;  

  
  ---------------------------------------------------------------------------
   --  Impute mode for the following columns: Tenure, CouponUsed, OrderCount. 
  --------------------------------------------------------------------------
  
  -- tenure
  UPDATE customer_churn
JOIN (
    SELECT Tenure AS mode_val
    FROM customer_churn
    GROUP BY Tenure
    ORDER BY COUNT(*) DESC
    LIMIT 1
) t
SET customer_churn.Tenure = t.mode_val
WHERE customer_churn.Tenure IS NULL AND customer_churn.CustomerID > 0;

-- couponused
UPDATE customer_churn
JOIN (
    SELECT CouponUsed AS mode_val
    FROM customer_churn
    GROUP BY CouponUsed
    ORDER BY COUNT(*) DESC
    LIMIT 1
) t
SET customer_churn.CouponUsed = t.mode_val
WHERE customer_churn.CouponUsed IS NULL
  AND customer_churn.CustomerID > 0;
  
  -- ordercount
  UPDATE customer_churn
JOIN (
    SELECT OrderCount AS mode_val
    FROM customer_churn
    GROUP BY OrderCount
    ORDER BY COUNT(*) DESC
    LIMIT 1
) t
SET customer_churn.OrderCount = t.mode_val
WHERE customer_churn.OrderCount IS NULL
  AND customer_churn.CustomerID > 0;
  
-- Handle outliers warehousetohome>100

-------------------------------------------------------------------------------------
delete from customer_churn
where WarehouseToHome >100;

---------------------------------------
  -- Dealing with Inconsistencies:
 -------------------------------------
 
  update customer_churn
  set PreferredLoginDevice = 'Mobile Phone'
  where PreferredLoginDevice = 'Phone' ;
  
 update customer_churn
  set PreferedOrderCat  = 'Mobile Phone'
  where PreferedOrderCat = 'Mobile' ;
  
-- Standardize Payment mode values 
-------------------------------------------------
 update customer_churn
  set PreferredPaymentMode = 'Cash on Delivery'
  where PreferredPaymentMode = 'COD';
 
 update customer_churn
  set PreferredPaymentMode = 'Credit Card'
  where PreferredPaymentMode = 'CC';
  
  
  -- Column Renaming
  -------------------------------------------
  
alter table customer_churn
rename column PreferedOrderCat to PreferredOrderCat;

alter table customer_churn
rename column HourSpendOnApp to HoursSpendOnApp;

-- createing new columns
--------------------------------------------------

alter table customer_churn
add column ComplaintRecevied varchar(30);

update customer_churn
set ComplaintRecevied = case
when Complain = 1 then 'Yes'
else 'No'
end ; 


alter table customer_churn
add column ChurnStatus varchar(30);

update customer_churn
set ChurnStatus = case
when Churn = 1 then 'Churned'
else'Active'
end ;

-- Column Dropping --
---------------------------------------------
alter table customer_churn
drop column Churn;

alter table customer_churn
drop column Complain;

-------------------------------------------------------------------
-- Data Exploration and Analysis
-------------------------------------------------------------------

-- 1  count of churned and active customers
------------------------------------------------------------
  
select Churnstatus,count(*) as Customercount
from customer_churn
group by Churnstatus ;

-- 2  average tenure and total cashback amount of churned customers 
-----------------------------------------------------------------------------------------
 
select avg(Tenure) as avgTenure,
sum(CashbackAmount) as TotalCashback
from customer_churn
where Churnstatus = 'Churned';

-- 3   percentage of churned customers who complained.
-----------------------------------------------------------------------------------------

select count(*) * 100.0/(select count(*) from customer_churn where Churnstatus = 'Churned')  
AS PercentChurnedWithComplaint
from customer_churn
where Churnstatus = 'Churned' and ComplaintRecevied = 'Yes';

-- 4   city tier with the highest churned customers preferred Laptop & Accessory 
----------------------------------------------------------------------------------------

select CityTire, count(*) as Churnedcount from customer_churn
where Churnstatus ='Churned'
and PreferredOrderCat = 'Laptop & Accessory'
group by CityTire
order by Churnedcount desc
limit 1;

-- 5  most preferred payment mode among active customers
-------------------------------------------------------------------

 select PreferredPaymentMode,count(*) as Modecount
from customer_churn
where Churnstatus = 'Active'
group by PreferredPaymentMode
order by Modecount
limit 1;

-- 6 Total order amount hike(single+mobil phone order)
 -----------------------------------------------------------------
 
select sum( OrderAmountHikeFromLastYear ) as Totalhike
from customer_churn
where MaritalStatus = 'Single'
and PreferredOrderCat = 'Mobile Phone'; 

-- 7 Average devices registered(UPI users)
---------------------------------------------------------------

select avg(NumberOfDeviceRegistered) as avgdevice
from customer_churn
where PreferredPaymentMode = 'UPI';

-- 8 Citytier with highest number of customers
---------------------------------------------------------------

select CityTier,count(*) as customercount
from customer_churn
group by CityTier
order by customercount desc
limit 1;

-- 9 Gender with highest coupen usage
----------------------------------------------------------------

select Gender, sum(CouponUsed) as Totalcoupons
from customer_churn
group by Gender
order by Totalcoupons desc
limit 1;

-- 10 Customers and maximum hour spent per order category
-------------------------------------------------------------------

select PreferredOrderCat,count(*) as customercount,
max(HoursSpendOnApp) as maxhour
from customer_churn
group by PreferredOrderCat;

-- 11 Total order count (credit card+ maximum satisfaction)
-------------------------------------------------------------------

select sum(OrderCount) as Totalorders
from customer_churn
where PreferredPaymentMode = 'Credit card'
and SatisfactionScore = (select max(SatisfactionScore) from customer_churn);

-- 12 AVG satisfactionscore of customers who complained
------------------------------------------------------------------

select avg(SatisfactionScore) as avgscore
from customer_churn
where ComplaintRecevied = 'Yes';

-- 13 Preferred order category (customers with>5 coupons)
--------------------------------------------------------------

select distinct PreferredOrderCat
from customer_churn
where CouponUsed>5;

-- 14 Top 3 order categories by avg cashback
----------------------------------------------------------

select PreferredOrderCat, avg(CashBackAmount) as avgcash
from customer_churn
group by PreferredOrderCat
order by avgcash
limit 3;

-- 15 Payment modes
-----------------------------------------------------------
select PreferredPaymentMode,
round(avg(Tenure),2) as avg_tenure,
sum(OrderCount) as totalorder
from customer_churn
group by PreferredPaymentMode
having round(avg(Tenure))=10
and sum(OrderCount)>500;
   
-- 16 Categorize distance and churn breakdown
---------------------------------------------------------

select 
case
    when WarehouseToHome <=5 then 'Vert Close Distance'
    when WarehouseToHome <=10 then 'Close Distence'
    when WarehouseToHome <=15 then 'Moderate Distance'
    else 'Far Distance'
    end as DistanceCategory,
    ChurnStatus,count(*) as customercount
    from customer_churn
    group by DistanceCategory,ChurnStatus ;
    
    -- 17 Married,citytier-1,order>average
    ------------------------------------------------------------
    
    select*from customer_churn
    where MaritalStatus = 'Married'
    and CityTier = 1
    and OrderCount>(select avg(OrderCount) from customer_churn);
    
    -- Create table Customerreturns
    ------------------------------------------------------
    
    create table customer_returns (
    ReturnID int primary key,
    CustomerID int,
    ReturnDate date,
    RefundAmount int
);

insert into customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) values
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

-- return details along with the customer details of those who have 
 -- churned and have made complaints
 ---------------------------------------------------------------------------

select r.ReturnID,
       r. ReturnDate,
       r. RefundAmount,
       c.CustomerID,
       C.PreferredPaymentMode,
       c.ChurnStatus
from customer_returns r
join customer_churn c
on r.customerID = c.customerID
where c.ChurnStatus = 'Churned'
and c. ComplaintRecevied = 'Yes';