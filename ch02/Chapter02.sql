----------------------------------------------------
------   SQL Server 2019 Developer’s Guide	 -------
---- Chapter 02 - Review of the T-SQL Language -----
----------------------------------------------------

----------------------------------------------------
-- Section 1: Transact-SQL SELECT
----------------------------------------------------

-- SELECT..FROM..WHERE..GROUP BY..HAVING..ORDER BY

-- The simplest query
USE WideWorldImportersDW;
SELECT *
FROM Dimension.Customer;

-- Projection - specifying columns
SELECT [Customer Key], [WWI Customer ID],
  [Customer], [Buying Group]
FROM Dimension.Customer;

-- Adding column aliases
SELECT [Customer Key] AS CustomerKey,
  [WWI Customer ID] AS CustomerId,
  [Customer],
  [Buying Group] AS BuyingGroup
FROM Dimension.Customer;

-- Filtering unknown customer
SELECT [Customer Key] AS CustomerKey,
  [WWI Customer ID] AS CustomerId,
  [Customer], 
  [Buying Group] AS BuyingGroup
FROM Dimension.Customer
WHERE [Customer Key] <> 0;

-- Joining to sales fact table and adding table aliases
SELECT c.[Customer Key] AS CustomerKey,
  c.[WWI Customer ID] AS CustomerId,
  c.[Customer], 
  c.[Buying Group] AS BuyingGroup,
  f.Quantity,
  f.[Total Excluding Tax] AS Amount,
  f.Profit
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key];
-- 228265 rows

-- Filtering unknown customer
SELECT c.[Customer Key] AS CustomerKey,
  c.[WWI Customer ID] AS CustomerId,
  c.[Customer], 
  c.[Buying Group] AS BuyingGroup,
  f.Quantity,
  f.[Total Excluding Tax] AS Amount,
  f.Profit
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0;
-- 143968 rows

-- Joining sales fact table with dimension Date
SELECT d.Date, f.[Total Excluding Tax],
  f.[Delivery Date Key]
FROM Fact.Sale AS f
  INNER JOIN Dimension.Date AS d
    ON f.[Delivery Date Key] = d.Date;
-- 227981 rows

-- Using a LEFT OUTER JOIN and ordering the result
SELECT d.Date, f.[Total Excluding Tax],
  f.[Delivery Date Key], f.[Invoice Date Key]
FROM Fact.Sale AS f
  LEFT OUTER JOIN Dimension.Date AS d
    ON f.[Delivery Date Key] = d.Date
ORDER BY f.[Invoice Date Key] DESC;
-- 228265 rows
-- For the last invoice date (2016-05-31), delivery date is NULL

-- Joining multiple tables and controlling outer join order
-- Sales - fact table & all dimensions
SELECT cu.[Customer Key] AS CustomerKey, cu.Customer,
  ci.[City Key] AS CityKey, ci.City, 
  ci.[State Province] AS StateProvince, ci.[Sales Territory] AS SalesTeritory,
  d.Date, d.[Calendar Month Label] AS CalendarMonth, 
  d.[Calendar Year] AS CalendarYear,
  s.[Stock Item Key] AS StockItemKey, s.[Stock Item] AS Product, s.Color,
  e.[Employee Key] AS EmployeeKey, e.Employee,
  f.Quantity, f.[Total Excluding Tax] AS TotalAmount, f.Profit
FROM (Fact.Sale AS f
  INNER JOIN Dimension.Customer AS cu
    ON f.[Customer Key] = cu.[Customer Key]
  INNER JOIN Dimension.City AS ci
    ON f.[City Key] = ci.[City Key]
  INNER JOIN Dimension.[Stock Item] AS s
    ON f.[Stock Item Key] = s.[Stock Item Key]
  INNER JOIN Dimension.Employee AS e
    ON f.[Salesperson Key] = e.[Employee Key])
  LEFT OUTER JOIN Dimension.Date AS d
    ON f.[Delivery Date Key] = d.Date;
-- 228265 rows

-- Checking the number if rows in the sales fact table
-- Introducing an aggregate function
SELECT COUNT(*) AS SalesCount
FROM Fact.Sale;
-- 228265

-- Aggregates in groups - introducting GROUP BY
SELECT c.Customer,
  SUM(f.Quantity) AS TotalQuantity,
  SUM(f.[Total Excluding Tax]) AS TotalAmount,
  COUNT(*) AS InvoiceLinesCount
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0
GROUP BY c.Customer;
-- 402 rows

-- Customers with more than 400 sales
-- Filtering aggregates - introducing HAVING
-- Note: can't use column aliases in HAVING
SELECT c.Customer,
  SUM(f.Quantity) AS TotalQuantity,
  SUM(f.[Total Excluding Tax]) AS TotalAmount,
  COUNT(*) AS InvoiceLinesCount
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0
GROUP BY c.Customer
HAVING COUNT(*) > 400;
-- 45 rows

-- Customers with more than 400 sales,
-- ordered by sales count descending
-- Note: can use column aliases in ORDER BY
SELECT c.Customer,
  SUM(f.Quantity) AS TotalQuantity,
  SUM(f.[Total Excluding Tax]) AS TotalAmount,
  COUNT(*) AS InvoiceLinesCount
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0
GROUP BY c.Customer
HAVING COUNT(*) > 400
ORDER BY InvoiceLinesCount DESC;
-- 45 rows


-- Advanced SELECT techniques

-- Subqueries
SELECT c.Customer,
  f.Quantity,
  (SELECT SUM(f1.Quantity) FROM Fact.Sale AS f1
   WHERE f1.[Customer Key] = c.[Customer Key]) AS TotalCustomerQuantity,
  f2.TotalQuantity
FROM (Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key])
  CROSS JOIN 
    (SELECT SUM(f2.Quantity) FROM Fact.Sale AS f2
	 WHERE f2.[Customer Key] <> 0) AS f2(TotalQuantity)
WHERE c.[Customer Key] <> 0
ORDER BY c.Customer, f.Quantity DESC;

-- Window functions
SELECT c.Customer,
  f.Quantity,
  SUM(f.Quantity)
   OVER(PARTITION BY c.Customer) AS TotalCustomerQuantity,
  SUM(f.Quantity)
   OVER() AS TotalQuantity
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0
ORDER BY c.Customer, f.Quantity DESC;

-- Row number in partitions and total
SELECT c.Customer,
  f.Quantity,
  ROW_NUMBER()
   OVER(PARTITION BY c.Customer
        ORDER BY f.Quantity DESC) AS CustomerOrderPosition,
  ROW_NUMBER()
   OVER(ORDER BY f.Quantity DESC) AS TotalOrderPosition
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0
ORDER BY c.Customer, f.Quantity DESC;

-- Running total quantity per customer and
-- moving average over last three sales keys
SELECT c.Customer,
  f.[Sale Key] AS SaleKey,
  f.Quantity,
  SUM(f.Quantity)
   OVER(PARTITION BY c.Customer
        ORDER BY [Sale Key]
	    ROWS BETWEEN UNBOUNDED PRECEDING
                 AND CURRENT ROW) AS Q_RT,
  AVG(f.Quantity)
   OVER(PARTITION BY c.Customer
        ORDER BY [Sale Key]
	    ROWS BETWEEN 2 PRECEDING
                 AND CURRENT ROW) AS Q_MA
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0
ORDER BY c.Customer, f.[Sale Key];

-- Top 3 orders by quantity for Tailspin Toys (Aceitunas, PR) 
SELECT c.Customer,
  f.[Sale Key] AS SaleKey,
  f.Quantity
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.Customer = N'Tailspin Toys (Aceitunas, PR)'
ORDER BY f.Quantity DESC
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;
-- 3 rows

-- Top 3 orders by quantity with ties
SELECT TOP 3 WITH TIES
  c.Customer,
  f.[Sale Key] AS SaleKey,
  f.Quantity
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.Customer = N'Tailspin Toys (Aceitunas, PR)'
ORDER BY f.Quantity DESC;
-- 4 rows

-- Top 3 orders by quantity for each customer
-- Introducing APPLY
SELECT c.Customer,
  t3.SaleKey, t3.Quantity
FROM Dimension.Customer AS c
  CROSS APPLY (SELECT TOP(3) 
                 f.[Sale Key] AS SaleKey,
                 f.Quantity
                FROM Fact.Sale AS f
                WHERE f.[Customer Key] = c.[Customer Key]
                ORDER BY f.Quantity DESC) AS t3
WHERE c.[Customer Key] <> 0
ORDER BY c.Customer, t3.Quantity DESC;

-- Calculating averages and standard deviation
-- for customers' orders
-- Introducing common table expressions (CTEs)
WITH CustomerSalesCTE AS
(
SELECT c.Customer, 
  SUM(f.[Total Excluding Tax]) AS TotalAmount,
  COUNT(*) AS InvoiceLinesCount
FROM Fact.Sale AS f
  INNER JOIN Dimension.Customer AS c
    ON f.[Customer Key] = c.[Customer Key]
WHERE c.[Customer Key] <> 0 
GROUP BY c.Customer
)
SELECT ROUND(AVG(TotalAmount), 6) AS AvgAmountPerCustomer,
  ROUND(STDEV(TotalAmount), 6) AS StDevAmountPerCustomer, 
  AVG(InvoiceLinesCount) AS AvgCountPerCustomer
FROM CustomerSalesCTE;
GO

-- Aggregating strings
WITH CitiesCTE AS
(
SELECT DISTINCT [State Province] AS State, City
FROM Dimension.City
WHERE Country <> N'N/A'
)
SELECT State,
 STRING_AGG (CAST(City AS NVARCHAR(max)), ';') WITHIN GROUP (ORDER BY City ASC) AS Cities
FROM CitiesCTE
GROUP BY State
ORDER BY State DESC;

-- Rowset function STRING_SPLIT
WITH CitiesCTE AS
(
SELECT DISTINCT [State Province] AS State, City
FROM Dimension.City
WHERE Country <> N'N/A'
),
CitiesByStateCTE AS
(
SELECT State,
 STRING_AGG (CAST(City AS NVARCHAR(max)), ';') WITHIN GROUP (ORDER BY City ASC) AS Cities
FROM CitiesCTE
GROUP BY State
)
SELECT State, value AS City
FROM CitiesByStateCTE
 CROSS APPLY STRING_SPLIT(Cities, ';')
ORDER BY State; 
GO


----------------------------------------------------
-- Section 2: DDL, DML, and programmable objects
----------------------------------------------------

-- Creating two simple tables
IF OBJECT_ID(N'dbo.SimpleOrders', N'U') IS NOT NULL
   DROP TABLE dbo.SimpleOrders;
CREATE TABLE dbo.SimpleOrders
(
  OrderId   INT         NOT NULL,
  OrderDate DATE        NOT NULL,
  Customer  NVARCHAR(5) NOT NULL,
  CONSTRAINT PK_SimpleOrders PRIMARY KEY (OrderId)
);
GO

DROP TABLE IF EXISTS dbo.SimpleOrderDetails;
CREATE TABLE dbo.SimpleOrderDetails
(
  OrderId   INT NOT NULL,
  ProductId INT NOT NULL,
  Quantity  INT NOT NULL
   CHECK(Quantity <> 0),
  CONSTRAINT PK_SimpleOrderDetails
   PRIMARY KEY (OrderId, ProductId)
);
GO

-- Adding a foreign key
ALTER TABLE dbo.SimpleOrderDetails ADD CONSTRAINT FK_Details_Orders
FOREIGN KEY (OrderId) REFERENCES dbo.SimpleOrders(OrderId);
GO

-- Inserting some data
INSERT INTO dbo.SimpleOrders
 (OrderId, OrderDate, Customer)
VALUES
 (1, '20190701', N'CustA');
INSERT INTO dbo.SimpleOrderDetails
 (OrderId, ProductId, Quantity)
VALUES
 (1, 7, 100),
 (1, 3, 200);
GO

-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  INNER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
ORDER BY o.OrderId, od.ProductId;

-- Update a row
UPDATE dbo.SimpleOrderDetails
   SET Quantity = 150
WHERE OrderId = 1
  AND ProductId = 3;

-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  INNER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
ORDER BY o.OrderId, od.ProductId;
GO

-- Returning modifications - introducing OUTPUT
INSERT INTO dbo.SimpleOrders
 (OrderId, OrderDate, Customer)
OUTPUT inserted.*
VALUES
 (2, '20190701', N'CustB');
INSERT INTO dbo.SimpleOrderDetails
 (OrderId, ProductId, Quantity)
OUTPUT inserted.*
VALUES
 (2, 4, 200);
GO

-- Using a trigger to correct order dates in the past
-- with a default date 20160101

-- Insert of an old order date without a trigger 
INSERT INTO dbo.SimpleOrders
 (OrderId, OrderDate, Customer)
VALUES
 (3, '20100701', N'CustC');
-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer
FROM dbo.SimpleOrders AS o
ORDER BY o.OrderId;
GO

-- Create the trigger
IF OBJECT_ID(N'trg_SimpleOrders_OrdereDate', N'TR') IS NOT NULL
   DROP TRIGGER trg_SimpleOrders_OrdereDate;
GO
CREATE TRIGGER trg_SimpleOrders_OrdereDate
 ON dbo.SimpleOrders AFTER INSERT, UPDATE
AS
 UPDATE dbo.SimpleOrders
    SET OrderDate = '20190101'
 WHERE OrderDate < '20190101';
GO

-- Try to insert an old order date 
-- and update a valid order date 
INSERT INTO dbo.SimpleOrders
 (OrderId, OrderDate, Customer)
VALUES
 (4, '20100701', N'CustD');
UPDATE dbo.SimpleOrders
   SET OrderDate = '20110101'
 WHERE OrderId = 3;
-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
ORDER BY o.OrderId, od.ProductId;
GO

-- Creating stored procedures for inserts
IF OBJECT_ID(N'dbo.InsertSimpleOrder', N'P') IS NOT NULL
   DROP PROCEDURE dbo.InsertSimpleOrder;
GO
CREATE PROCEDURE dbo.InsertSimpleOrder
(@OrderId AS INT, @OrderDate AS DATE, @Customer AS NVARCHAR(5))
AS
INSERT INTO dbo.SimpleOrders
 (OrderId, OrderDate, Customer)
VALUES
 (@OrderId, @OrderDate, @Customer);
GO

-- Second procedure, first try
IF OBJECT_ID(N'dbo.InsertSimpleOrderDetail', N'P') IS NOT NULL
   DROP PROCEDURE dbo.InsertSimpleOrderDetail;
GO
CREATE PROCEDURE dbo.InsertSimpleOrderDetail
(@OrderId AS INT, @ProductId AS INT, @Quantity AS INT)
AS 
SELECT 1;
GO

-- Second try - error
CREATE PROCEDURE dbo.InsertSimpleOrderDetail
(@OrderId AS INT, @ProductId AS INT, @Quantity AS INT)
AS 
INSERT INTO dbo.SimpleOrderDetails
 (OrderId, ProductId, Quantity)
VALUES
 (@OrderId, @ProductId, @Quantity);
GO

-- Third try - success
CREATE OR ALTER PROCEDURE dbo.InsertSimpleOrderDetail
(@OrderId AS INT, @ProductId AS INT, @Quantity AS INT)
AS 
INSERT INTO dbo.SimpleOrderDetails
 (OrderId, ProductId, Quantity)
VALUES
 (@OrderId, @ProductId, @Quantity);
GO


-- Test the procedures
EXEC dbo.InsertSimpleOrder
 @OrderId = 5, @OrderDate = '20190702', @Customer = N'CustA';
EXEC dbo.InsertSimpleOrderDetail
 @OrderId = 5, @ProductId = 1, @Quantity = 50;
-- Inserting couple of order details
EXEC dbo.InsertSimpleOrderDetail
 @OrderId = 2, @ProductId = 5, @Quantity = 150;
EXEC dbo.InsertSimpleOrderDetail
 @OrderId = 2, @ProductId = 6, @Quantity = 250;
EXEC dbo.InsertSimpleOrderDetail
 @OrderId = 1, @ProductId = 5, @Quantity = 50;
EXEC dbo.InsertSimpleOrderDetail
 @OrderId = 1, @ProductId = 6, @Quantity = 200;
-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
ORDER BY o.OrderId, od.ProductId;
GO

-- Creating a view to quickly find orders without details
CREATE VIEW dbo.OrdersWithoutDetails
AS
SELECT o.OrderId, o.OrderDate, o.Customer
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
WHERE od.OrderId IS NULL;
GO
-- Using the view
SELECT OrderId, OrderDate, Customer
FROM dbo.OrdersWithoutDetails;
GO

-- Creating a function to select top 2 order details by quantity for an order
CREATE FUNCTION dbo.Top2OrderDetails
(@OrderId AS INT)
RETURNS TABLE
AS RETURN
SELECT TOP 2 ProductId, Quantity
FROM dbo.SimpleOrderDetails
WHERE OrderId = @OrderId
ORDER BY Quantity DESC;
GO

-- Using the function with OUTER APPLY
SELECT o.OrderId, o.OrderDate, o.Customer,
  t2.ProductId, t2.Quantity
FROM dbo.SimpleOrders AS o
  OUTER APPLY dbo.Top2OrderDetails(o.OrderId) AS t2
ORDER BY o.OrderId, t2.Quantity DESC;
GO


----------------------------------------------------
-- Section 3: Transactions and error handling
----------------------------------------------------

-- No error handling
EXEC dbo.InsertSimpleOrder
 @OrderId = 6, @OrderDate = '20190706', @Customer = N'CustE';
EXEC dbo.InsertSimpleOrderDetail
 @OrderId = 6, @ProductId = 2, @Quantity = 0;
-- Error 547 - The INSERT statement conflicted with the CHECK constraint
-- Quantity must be greater than 0

-- Try to insert order 6 another time
EXEC dbo.InsertSimpleOrder
 @OrderId = 6, @OrderDate = '20190706', @Customer = N'CustE';
-- Error 2627 - Violation of PRIMARY KEY constraint

-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
WHERE o.OrderId > 5
ORDER BY o.OrderId, od.ProductId;
GO

-- Handling errors with TRY..CATCH

-- Error in the first statement
BEGIN TRY
 EXEC dbo.InsertSimpleOrder
  @OrderId = 6, @OrderDate = '20190706', @Customer = N'CustF';
 EXEC dbo.InsertSimpleOrderDetail
  @OrderId = 6, @ProductId = 2, @Quantity = 5;
END TRY
BEGIN CATCH
 SELECT ERROR_NUMBER() AS ErrorNumber,
   ERROR_MESSAGE() AS ErrorMessage,
   ERROR_LINE() as ErrorLine;
END CATCH
-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
WHERE o.OrderId > 5
ORDER BY o.OrderId, od.ProductId;
-- 2nd command was not executed, control was
-- transferred immediately after the error to the catch block
GO

-- Error in the second statement
BEGIN TRY
 EXEC dbo.InsertSimpleOrder
  @OrderId = 7, @OrderDate = '20190706', @Customer = N'CustF';
 EXEC dbo.InsertSimpleOrderDetail
  @OrderId = 7, @ProductId = 2, @Quantity = 0;
END TRY
BEGIN CATCH
 SELECT ERROR_NUMBER() AS ErrorNumber,
   ERROR_MESSAGE() AS ErrorMessage,
   ERROR_LINE() as ErrorLine;
END CATCH
-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
WHERE o.OrderId > 5
ORDER BY o.OrderId, od.ProductId;
-- 1st command was executed
GO

-- Using transactions
-- Error in the second statement
BEGIN TRY
 BEGIN TRANSACTION
  EXEC dbo.InsertSimpleOrder
   @OrderId = 8, @OrderDate = '20190706', @Customer = N'CustG';
  EXEC dbo.InsertSimpleOrderDetail
   @OrderId = 8, @ProductId = 2, @Quantity = 0;
 COMMIT TRANSACTION
END TRY
BEGIN CATCH
 SELECT ERROR_NUMBER() AS ErrorNumber,
   ERROR_MESSAGE() AS ErrorMessage,
   ERROR_LINE() as ErrorLine;
 IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;
END CATCH
-- Check the data
SELECT o.OrderId, o.OrderDate, o.Customer,
  od.ProductId, od.Quantity
FROM dbo.SimpleOrderDetails AS od
  RIGHT OUTER JOIN dbo.SimpleOrders AS o
    ON od.OrderId = o.OrderId
WHERE o.OrderId > 5
ORDER BY o.OrderId, od.ProductId;
-- 1st command was rolled back as well
GO

-- Clean up
DROP FUNCTION dbo.Top2OrderDetails;
DROP VIEW dbo.OrdersWithoutDetails;
DROP PROCEDURE dbo.InsertSimpleOrderDetail;
DROP PROCEDURE dbo.InsertSimpleOrder;
DROP TABLE dbo.SimpleOrderDetails;
DROP TABLE dbo.SimpleOrders;
GO


----------------------------------------------------
-- Section 4: Beyond relational
----------------------------------------------------

-- Spatial data
SELECT City,
  [Sales Territory] AS SalesTerritory,
  Location AS LocationBinary,
  Location.ToString() AS LocationLongLat
FROM Dimension.City
WHERE [City Key] <> 0
  AND [Sales Territory] NOT IN
      (N'External', N'Far West');
-- Check the spatial results
-- Only first 5000 objects displayed

-- Denver, Colorado data
SELECT [City Key] AS CityKey, City,
  [State Province] AS State,
  [Latest Recorded Population] AS Population,
  Location.ToString() AS LocationLongLat
FROM Dimension.City
WHERE [City Key] = 114129
  AND [Valid To] = '9999-12-31 23:59:59.9999999';

-- Distance between Denver and Seattle
DECLARE @g AS GEOGRAPHY;
DECLARE @h AS GEOGRAPHY;
DECLARE @unit AS NVARCHAR(50);
SET @g = (SELECT Location FROM Dimension.City
          WHERE [City Key] = 114129);
SET @h = (SELECT Location FROM Dimension.City
          WHERE [City Key] = 108657);
SET @unit = (SELECT unit_of_measure 
             FROM sys.spatial_reference_systems
             WHERE spatial_reference_id = @g.STSrid);
SELECT FORMAT(@g.STDistance(@h), 'N', 'en-us') AS Distance,
 @unit AS Unit;
GO

-- Major cities withing circle of 1,000 km around Denver, Colorado
DECLARE @g AS GEOGRAPHY;
SET @g = (SELECT Location FROM Dimension.City
          WHERE [City Key] = 114129);
SELECT DISTINCT City,
  [State Province] AS State,
  FORMAT([Latest Recorded Population], '000,000') AS Population,
  FORMAT(@g.STDistance(Location), '000,000.00') AS Distance
FROM Dimension.City
WHERE Location.STIntersects(@g.STBuffer(1000000)) = 1
  AND [Latest Recorded Population] > 200000
  AND [City Key] <> 114129
  AND [Valid To] = '9999-12-31 23:59:59.9999999'
ORDER BY Distance;
GO


----------------------------------------------------
------   SQL Server 2019 Developer’s Guide	 -------
---- Chapter 02 - Review of the T-SQL Language -----
----------------------------------------------------
