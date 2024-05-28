SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE OR ALTER VIEW [dba].[vw_DriveSpace_Rates]
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

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'VIEW', @level1name = N'vw_DriveSpace_Rates';
GO
