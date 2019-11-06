---------------------------------------------------------
--------	SQL Server 2019 Developer’s Guide    --------
------   Chapter 11 - Supporting R in SQL Server  -------
---------------------------------------------------------


----------------------------------------------------
-- Section 1: Introducing R
----------------------------------------------------
/* Creating RUser login and db user
USE [master]
GO
CREATE LOGIN [RUSer] WITH PASSWORD=N'Pa$$w0rd', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON
GO
USE [WideWorldImportersDW]
GO
CREATE USER [RUSer] FOR LOGIN [RUSer]
GO
USE [WideWorldImportersDW]
GO
ALTER ROLE [db_datareader] ADD MEMBER [RUSer]
GO
*/


----------------------------------------------------
-- Section 8: SQL Server R Services
----------------------------------------------------

-- Configure SQL Server to enable external scripts
USE master;
EXEC sys.sp_configure 'show advanced options', 1;
RECONFIGURE
EXEC sys.sp_configure 'external scripts enabled', 1; 
RECONFIGURE;
GO
-- Check the configuration
EXEC sys.sp_configure;
GO

-- Check R version
EXECUTE sys.sp_execute_external_script
 @language=N'R',
 @script = 
 N'str(OutputDataSet)
   OutputDataSet <- as.data.frame(R.version.string)'
WITH RESULT SETS ( ( PackageName nvarchar(50) ) );
GO

-- Check installed packages
EXECUTE sys.sp_execute_external_script
 @language=N'R',
 @script = 
 N'str(OutputDataSet)
   packagematrix <- installed.packages()
   NameOnly <- packagematrix[,1]
   OutputDataSet <- as.data.frame(NameOnly)'
WITH RESULT SETS ( ( PackageName nvarchar(20) ) );
GO

-- Create a table to store a model
USE AdventureWorksDW2017;
CREATE TABLE dbo.RModels
(Id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
 ModelName NVARCHAR(50) NOT NULL,
 Model VARBINARY(MAX) NOT NULL);
GO


-- Decision Trees model for the PREDICT T-SQL function 
DECLARE @model VARBINARY(MAX);
EXECUTE sys.sp_execute_external_script
  @language = N'R'
 ,@script = N'
   bbDTree <- rxDTree(BikeBuyer ~ NumberCarsOwned +
                        TotalChildren + Age + YearlyIncome,
                      data = TM)
   model <- rxSerializeModel(bbDTree, realtimeScoringOnly = TRUE)'
 ,@input_data_1 = N'
     SELECT CustomerKey, BikeBuyer, NumberCarsOwned,
	  TotalChildren, Age, YearlyIncome
     FROM dbo.vTargetMail;'
 ,@input_data_1_name =  N'TM'
 ,@params = N'@model VARBINARY(MAX) OUTPUT'
 ,@model = @model OUTPUT;
INSERT INTO dbo.RModels (ModelName, Model)
VALUES('bbDTree', @model);
GO

-- Check the models
SELECT *
FROM dbo.RModels;
GO


-- Use the PREDICT function
DECLARE @model VARBINARY(MAX) = 
(
  SELECT Model
  FROM dbo.RModels
  WHERE ModelName = 'bbDTree'
);
SELECT d.CustomerKey, d.BikeBuyer,
 d.NumberCarsOwned, d.TotalChildren, d.Age, 
 d.YearlyIncome, p.BikeBuyer_Pred
FROM PREDICT(MODEL = @model, DATA = dbo.vTargetMail AS d)
WITH(BikeBuyer_Pred FLOAT) AS p
ORDER BY d.CustomerKey;
GO


-- Using the skewness() function from the package moments
EXECUTE sys.sp_execute_external_script
 @language=N'R',
 @script = 
 N'library(moments)  
   skewness(TM$Age)'
 ,@input_data_1 = N'
     SELECT Age
     FROM dbo.vTargetMail;'
 ,@input_data_1_name =  N'TM';
GO
/* Error
Msg 39004, Level 16, State 20, Line 114
A 'R' script error occurred during execution... 
*/

-- Create external library
CREATE EXTERNAL LIBRARY moments
FROM (CONTENT = 'C:\SQL2019DevGuide\moments_0.14.zip') 
WITH (LANGUAGE = 'R');
GO

SELECT *
FROM sys.external_libraries;
GO

-- Using the skewness() function from the package moments again
EXECUTE sys.sp_execute_external_script
 @language=N'R',
 @script = 
 N'library(moments)  
   s <- skewness(TM$Age)
   OutputDataSet <- as.data.frame(s)'
 ,@input_data_1 = N'
     SELECT Age
     FROM dbo.vTargetMail;'
 ,@input_data_1_name =  N'TM'
WITH RESULT SETS ( ( AgeSkewness float ) );
GO

-- Clean up
USE AdventureWorksDW2017;
GO
DROP TABLE dbo.RModels;
DROP EXTERNAL LIBRARY moments;
GO
