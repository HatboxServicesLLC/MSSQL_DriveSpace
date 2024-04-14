SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*****************************************************************************************************************************************************
Name: dba.DriveSpace_Get_AverageOverPeriod
Creation Date: 03.12.2024
Author: CPearson

Description:Get the average rate of use for given drives, over given period. 


Version Naming Conventions
--------------------------------------
1.2
^ ^
| |
| +----- Version Minor: features, major bug fixes, etc.
+------- Version Major: syntax changes, join logic, table adds / removal changes, etc.

Revision History:
-----------------------
Revision Date | Revision Developer | Version Major | Version Minor  | Ticket 			| Revision Notes
------------------------------------------------------------------------------------------------------------------------
03.12.2024 CPearson        1                      0     			DO-2713		Initial stored procedure

Test Case:
-------------
- **this section should include detailed instructions of how to test the intended functionality of this stored procedure**

******************************************************************************************************************************************************/
CREATE FUNCTION [dba].[DriveSpace_Get_AverageOverPeriod]
(
    /*---------------------------------------
    --External Variable Declaration
    ---------------------------------------*/
    @StartDate DATETIME,
    @EndDate DATETIME,
    @DriveLetters NVARCHAR(125) NULL
/*---------------------------------------
---------------------------------------*/
)
RETURNS TABLE
AS
/*validation*/
--Start date and end date are valid
--start date is before end date
--DriveLetters is comma delimited list
/*--------------------------------------
--Internal Variable Declaration
--------------------------------------*/
/* Averaged over Period*/
RETURN
(
    SELECT v.Drive,
           v.Drive_Letter,
           --v.DriveTotalSpace_GB,
           --CONVERT(DATE,v.CapturedDateTime) AS CapturedDate,
           SUM(v.Change_GBaSecond) / COUNT(*) AS Sum_Change_GBaSecond,
           SUM(v.Change_GBaMinute) / COUNT(*) AS Change_GBaMinute,
           SUM(v.Change_GBaHour) / COUNT(*) AS Change_GBaHour
    FROM dba.vw_DriveSpace_Rates v
    WHERE v.CapturedDateTime
          BETWEEN @StartDate AND @EndDate
          AND
          (
              @DriveLetters IS NULL
              OR v.Drive_Letter IN
                 (
                     SELECT value FROM STRING_SPLIT(@DriveLetters, ',') drives
                 )
          )
    GROUP BY v.Drive,
             v.Drive_Letter
--v.DriveTotalSpace_GB,
--,CONVERT(DATE,v.CapturedDateTime)
);
GO
