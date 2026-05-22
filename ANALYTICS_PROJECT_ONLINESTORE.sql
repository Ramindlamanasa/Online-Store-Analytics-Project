CREATE DATABASE ONLINESTORE;

USE ONLINESTORE;
---------------------------------------------------------------------------------------------------------

SELECT * FROM Orders;

SELECT * FROM PEOPLE;

SELECT * FROM RETURNS;
-----------------------------------------------------------------------------------------
ALTER TABLE ORDERS
ALTER COLUMN SHIP_DATE DATE;
----------------------------------------------------------------------------------------------
--Q1->Identify customers whose total sales are above the average sales of all customers
------------------------------------------------------------------------------------------
SELECT * FROM ORDERS;

SELECT  [CUSTOMER_ID], [CUSTOMER NAME],AVG(SALES) AS 'AVG SALES', SUM(SALES) AS 'TS' FROM ORDERS
GROUP BY [CUSTOMER_ID],[CUSTOMER NAME]
HAVING SUM(SALES) > (SELECT AVG(SALES) FROM ORDERS);

---------------------------------------------------------------------------------------------------
--Q2--Find the customer who has made the maximum number of  orders in each category:
-------------------------------------------------------------------------------------------

SELECT * FROM(
SELECT  [CUSTOMER_ID],[CUSTOMER NAME],CATEGORY,COUNT([ORDER_ID]) AS 'NO OF ORDERS',RANK() OVER (PARTITION BY CATEGORY ORDER BY COUNT([ORDER_ID]) DESC) AS RNK FROM ORDERS
GROUP BY CATEGORY,[CUSTOMER_ID],[CUSTOMER NAME]) T WHERE RNK = 1;

-------------------------------------------------------------------------------------------------------------
--Q3--Find the top 3 products in each category based on their sales.
---------------------------------------------------------------------
SELECT * 
FROM (
     SELECT  [PRODUCT ID],[PRODUCT NAME], CATEGORY, SALES, RANK() OVER (PARTITION BY CATEGORY ORDER BY SALES DESC) AS RNKED
	 FROM ORDERS) T WHERE RNKED <= 3;

--------------------------------------------------------------------------------------------
---Q4- Calculate year-over-year (YoY) sales growth  
----------------------------------------------------------------------------------------------
SELECT 
    YEAR(A.Order_Date) AS Year,
    SUM(A.Sales) AS CurrentYearSales,
    SUM(B.Sales) AS PreviousYearSales,
    SUM(A.Sales) - SUM(B.Sales) AS YoY_Growth
FROM Orders A
LEFT JOIN Orders B
    ON YEAR(A.Order_Date) = YEAR(B.Order_Date) + 1
GROUP BY YEAR(A.Order_Date)
ORDER BY Year;
---------------------------------------------------------------------------
--Q5--Find the most profitable shipping mode for each region
----------------------------------------------------------------------------
WITH REGIONALPROFIT AS(
   SELECT 
          [SHIP MODE], REGION , SUM(PROFIT) AS 'TOTAL_PROFIT',
          ROW_NUMBER() OVER(PARTITION BY REGION ORDER BY SUM(PROFIT) DESC) AS RNK 
   FROM ORDERS
   GROUP BY REGION,[SHIP MODE])

 SELECT [SHIP MODE], REGION ,TOTAL_PROFIT 
 FROM REGIONALPROFIT
 WHERE RNK = 1
 ORDER BY TOTAL_PROFIT DESC; 

 --------------------------------------------------------------------
 ---In the table Orders with columns OrderID, CustomerID, OrderDate, TotalAmount, and Status. 
 ---You need to create a stored procedure Get_Customer_Orders that takes a CustomerID as input and returns a table with the following columns,
 --- you will need to create a function also that calculates the number of days between two dates
 -----------------------------------------------------------------------
 CREATE FUNCTION GetDaysDifference( @DATE1 DATE, @DATE2 DATE)
 RETURNS INT
 AS 
 BEGIN 
   DECLARE @D AS INT;
   SET @D = DATEDIFF(DAY,@DATE1,@DATE2);
   RETURN @D;
 END

 SELECT dbo.GetDaysDifference('2026-03-10','2026-06-10');

 ---------------------------------------------------
 ---CREATING STORED PROCEDURE------------------
 -----------------------------------------
CREATE PROCEDURE Get_Customers_Orders 
    @CID VARCHAR(20)
AS 
BEGIN

    DECLARE @TotalOrders INT
    DECLARE @TotalAmount DECIMAL(10,2)
    DECLARE @AVGAmount DECIMAL(10,2)
    DECLARE @LastOrderDate DATE
    DECLARE @DaysSinceLastOrder INT

    SELECT 
        @TotalOrders = COUNT(*),
        @TotalAmount = SUM(SALES),
        @AVGAmount = AVG(SALES),
        @LastOrderDate = MAX(Order_Date)
    FROM Orders
    WHERE Customer_ID = @CID

    SET @DaysSinceLastOrder = dbo.GetDaysDifference(@LastOrderDate, GETDATE())

    SELECT 
        Order_ID,
        Customer_ID,
        Order_Date,
        Sales,
        @TotalOrders AS TotalOrders,
        @TotalAmount AS TotalAmount,
        @AVGAmount AS AvgAmount,
        @LastOrderDate AS LastOrderDate,
        @DaysSinceLastOrder AS DaysSinceLastOrder
    FROM Orders
    WHERE Customer_ID = @CID

END

EXEC dbo.Get_Customers_Orders 'SJ-20215'
-------------------------------------------------------------------------------------------
