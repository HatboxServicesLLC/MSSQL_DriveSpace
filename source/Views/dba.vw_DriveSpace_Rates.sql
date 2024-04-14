SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************************************************************************************************************
Name: dba.vw_DriveSpace_Rates
Creation Date: 03.11.2024
Author: CPearson

Description:Takes the DriveSpaceHistory table and builds rates off the data for drive usage over seconds, minutes and hours.  


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
03.11.2024 CPearson        1                      0     			DO-2713		Initial stored procedure

 

 

Test Case:
-------------
- **this section should include detailed instructions of how to test the intended functionality of this stored procedure**

******************************************************************************************************************************************************/
CREATE    VIEW [dba].[vw_DriveSpace_Rates]
AS
WITH temp
AS (
   SELECT *,
          (DriveTotalSpace_GB - DriveFreeSpace_GB) AS UsedSpace_GB
   FROM master.dba.DriveSpaceHistory d),
     arg01
AS (SELECT t.id,
           [Drive],
           [Drive_Letter],
           [DriveTotalSpace_GB],
           UsedSpace_GB,
           t.DriveFreeSpace_GB,
           Drive_UsedPrecentage,
           Deltas.Change_TotalSpace_GB,
           Deltas.Change_UsedSpace_GB,
           Deltas.Change_OverXSecs,
           Deltas.Change_OverXMins,
           Deltas.Change_OverXHours,
           t.CapturedDateTime
    FROM temp t
        JOIN
        (
            SELECT t.id,
                   DriveTotalSpace_GB  
                   - LAG(DriveTotalSpace_GB, 1, 0) OVER (PARTITION BY Drive ORDER BY CapturedDateTime) AS Change_TotalSpace_GB,
                   UsedSpace_GB - LAG(UsedSpace_GB, 1, 0) OVER (PARTITION BY Drive ORDER BY CapturedDateTime) AS Change_UsedSpace_GB,
                   DATEDIFF(
                               SECOND,
                               LAG(CapturedDateTime, 1, CapturedDateTime) OVER (PARTITION BY Drive ORDER BY CapturedDateTime),
                               CapturedDateTime
                           ) AS Change_OverXSecs,
                   DATEDIFF(
                               SECOND,
                               LAG(CapturedDateTime, 1, CapturedDateTime) OVER (PARTITION BY Drive ORDER BY CapturedDateTime),
                               CapturedDateTime
                           ) / 60.000 AS Change_OverXMins,
                   DATEDIFF(
                               SECOND,
                               LAG(CapturedDateTime, 1, CapturedDateTime) OVER (PARTITION BY Drive ORDER BY CapturedDateTime),
                               CapturedDateTime
                           ) / 60.00 / 60.0 AS Change_OverXHours
            FROM temp t
        ) AS Deltas
            ON Deltas.id = t.id
    WHERE Deltas.Change_OverXSecs <> 0
     -- /*PERIOD*/
     -- T.CapturedDateTime BETWEEN @Start AND @End
     --order by drive, captureddatetime
     ),
     arg02
AS (SELECT arg01.id,
           arg01.Drive,
           arg01.Drive_Letter,
           arg01.DriveTotalSpace_GB,
           arg01.UsedSpace_GB,
           arg01.DriveFreeSpace_GB,
           arg01.Drive_UsedPrecentage,
           arg01.Change_TotalSpace_GB,
           arg01.Change_UsedSpace_GB,
           arg01.Change_OverXSecs,
           arg01.Change_OverXMins,
           arg01.Change_OverXHours,
           arg01.CapturedDateTime,
           (arg01.Change_UsedSpace_GB / arg01.Change_OverXSecs) AS Change_GBaSecond,
           (arg01.Change_UsedSpace_GB / arg01.Change_OverXMins) AS Change_GBaMinute,
           (arg01.Change_UsedSpace_GB / arg01.Change_OverXHours) AS Change_GBaHour
    FROM arg01)
SELECT arg02.id,
       arg02.Drive,
       arg02.Drive_Letter,
       arg02.DriveTotalSpace_GB,
       arg02.UsedSpace_GB,
       arg02.DriveFreeSpace_GB,
       arg02.Drive_UsedPrecentage,
       arg02.Change_TotalSpace_GB,
       arg02.Change_UsedSpace_GB,
       arg02.Change_OverXSecs,
       arg02.Change_OverXMins,
       arg02.Change_OverXHours,
       arg02.CapturedDateTime,
       arg02.Change_GBaSecond,
       arg02.Change_GBaMinute,
       arg02.Change_GBaHour
FROM arg02;
GO
