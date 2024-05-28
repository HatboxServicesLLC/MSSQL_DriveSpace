SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE OR ALTER FUNCTION [dba].[DriveSpace_Get_AverageOverPeriod]
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

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'FUNCTION', @level1name = N'DriveSpace_Get_AverageOverPeriod';
GO
