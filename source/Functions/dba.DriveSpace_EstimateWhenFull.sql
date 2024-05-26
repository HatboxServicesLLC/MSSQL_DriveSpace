SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE OR ALTER FUNCTION [dba].[DriveSpace_EstimateWhenFull] 
(
/*---------------------------------------
--External Variable Declaration
---------------------------------------*/
	@EndDate DATETIME = NULL,
	@DriveLetters NVARCHAR(500) = null,
	@Version NVARCHAR(12) = '1.0.0' OUTPUT/*[MAJOR].[MINOR].[BUG]*/
/*---------------------------------------
---------------------------------------*/
)
RETURNS @ResultSet TABLE 
(
    [RateBaseOn] varchar(11),
    [Drive] nvarchar(260),
    [Drive_Letter] nvarchar(10),
    [Sum_Change_GBaSecond] decimal(36, 8),
    [Change_GBaMinute] decimal(36, 8),
    [Change_GBaHour] decimal(36, 8),
    [DriveSpaceHistory_id] bigint,
    [DriveTotalSpace_GB] decimal(38, 8),
    [DriveFreeSpace_GB] decimal(38, 8),
    [Drive_UsedPrecentage] decimal(38, 8),
    [CapturedDateTime] datetime,
    [SecondsTillFull] decimal(38, 6),
    [MinutesTillFull] decimal(38, 6),
    [HoursTillFull] decimal(38, 6)
)
AS
BEGIN
	DECLARE @StartDate DATETIME = NULL ;
		IF @EndDate IS NULL
		BEGIN 
		SET @EndDate = GETDATE();
		END
					
		/*--GET RATES BASED OFF DIFFERENT TIME PERIODS--*/
		/*last hour*/
		SET @StartDate = DATEADD(HOUR, -1, @EndDate);
		DECLARE @Results_LastHour TABLE 
		(
		    Drive NVARCHAR(260),
		    Drive_Letter NVARCHAR(10),
		    Sum_Change_GBaSecond DECIMAL(36, 8),
		    Change_GBaMinute DECIMAL(36, 8),
		    Change_GBaHour DECIMAL(36, 8)
		);
		INSERT INTO @Results_LastHour
		(
		    Drive,
		    Drive_Letter,
		    Sum_Change_GBaSecond,
		    Change_GBaMinute,
		    Change_GBaHour
		)
		SELECT *
		FROM dba.DriveSpace_Get_AverageOverPeriod (@StartDate, @EndDate, @DriveLetters);
		
		/*last 24 hours*/
		SET @StartDate = DATEADD(HOUR, -24, @EndDate);
		DECLARE @Results_Last24Hour TABLE 
		(
		    Drive NVARCHAR(260),
		    Drive_Letter NVARCHAR(10),
		    Sum_Change_GBaSecond DECIMAL(36, 8),
		    Change_GBaMinute DECIMAL(36, 8),
		    Change_GBaHour DECIMAL(36, 8)
		);
		INSERT INTO @Results_Last24Hour
		(
		    Drive,
		    Drive_Letter,
		    Sum_Change_GBaSecond,
		    Change_GBaMinute,
		    Change_GBaHour
		)
		SELECT *
		FROM dba.DriveSpace_Get_AverageOverPeriod (@StartDate, @EndDate, @DriveLetters);

		/*last 7 days*/
		SET @StartDate = DATEADD(DAY, -7, @EndDate);
		DECLARE @Results_Last7Days TABLE 
		(
		    Drive NVARCHAR(260),
		    Drive_Letter NVARCHAR(10),
		    Sum_Change_GBaSecond DECIMAL(36, 8),
		    Change_GBaMinute DECIMAL(36, 8),
		    Change_GBaHour DECIMAL(36, 8)
		);
		INSERT INTO @Results_Last7Days
		(
		    Drive,
		    Drive_Letter,
		    Sum_Change_GBaSecond,
		    Change_GBaMinute,
		    Change_GBaHour
		)
		SELECT *
		FROM dba.DriveSpace_Get_AverageOverPeriod (@StartDate, @EndDate, @DriveLetters);

		/*last 30 days*/
		SET @StartDate = DATEADD(DAY, -30, @EndDate);
		DECLARE @Results_Last30Days TABLE 
		(
		    Drive NVARCHAR(260),
		    Drive_Letter NVARCHAR(10),
		    Sum_Change_GBaSecond DECIMAL(36, 8),
		    Change_GBaMinute DECIMAL(36, 8),
		    Change_GBaHour DECIMAL(36, 8)
		);
		INSERT INTO @Results_Last30Days
		(
		    Drive,
		    Drive_Letter,
		    Sum_Change_GBaSecond,
		    Change_GBaMinute,
		    Change_GBaHour
		)
		SELECT *
		FROM dba.DriveSpace_Get_AverageOverPeriod (@StartDate, @EndDate, @DriveLetters);

		/*last 32 weeks on day*/
		SET @StartDate = DATEADD(WEEK, -32, @EndDate);
		DECLARE @Results_Last32Weeks TABLE 
		(
		    Drive NVARCHAR(260),
		    Drive_Letter NVARCHAR(10),
		    Sum_Change_GBaSecond DECIMAL(36, 8),
		    Change_GBaMinute DECIMAL(36, 8),
		    Change_GBaHour DECIMAL(36, 8)
		);
		INSERT INTO @Results_Last32Weeks
		(
		    Drive,
		    Drive_Letter,
		    Sum_Change_GBaSecond,
		    Change_GBaMinute,
		    Change_GBaHour
		)
		SELECT *
		FROM dba.DriveSpace_Get_AverageOverPeriod (@StartDate, @EndDate, @DriveLetters);

		/*combined list*/
		DECLARE @Results_Combined TABLE 
		(
		[RateBaseOn] NVARCHAR(11),
		[Drive] NVARCHAR(260),
		[Drive_Letter] NVARCHAR(10),
		[Sum_Change_GBaSecond] DECIMAL(36, 8),
		[Change_GBaMinute] DECIMAL(36, 8),
		[Change_GBaHour] DECIMAL(36, 8)
		);

		INSERT INTO @Results_Combined
		SELECT *
		FROM
		(
		    SELECT 'LastHour' AS RateBaseOn,
		           *
		    FROM @Results_LastHour
		    UNION
		    SELECT 'Last24Hour' AS RateBaseOn,
		           *
		    FROM @Results_Last24Hour
		    UNION
		    SELECT 'Last7Days' AS RateBaseOn,
		           *
		    FROM @Results_Last7Days
		    UNION
		    SELECT 'Last30Days' AS RateBaseOn,
		           *
		    FROM @Results_Last30Days
		    UNION
		    SELECT 'Last32weeks' AS RateBaseOn,
		           *
		    FROM @Results_Last32Weeks
		) unionSet;
		
		/*identify now long till full per each of the rates collected*/
		INSERT INTO @ResultSet 
		SELECT rc.RateBaseOn,
		       rc.Drive,
		       rc.Drive_Letter,
		       rc.Sum_Change_GBaSecond,
		       rc.Change_GBaMinute,
		       rc.Change_GBaHour,
		       mr.id AS DriveSpaceHistory_id,
		       mr.DriveTotalSpace_GB,
		       mr.DriveFreeSpace_GB,
		       mr.Drive_UsedPrecentage,
		       mr.CapturedDateTime,
		       CASE WHEN mr.DriveFreeSpace_GB <= 0 THEN 0 ELSE (mr.DriveFreeSpace_GB / rc.Sum_Change_GBaSecond) END AS SecondsTillFull,
		       CASE WHEN mr.DriveFreeSpace_GB <= 0 THEN 0 ELSE (mr.DriveFreeSpace_GB / rc.Change_GBaMinute) END AS MinutesTillFull,
		       CASE WHEN mr.DriveFreeSpace_GB <= 0 THEN 0 ELSE (mr.DriveFreeSpace_GB / rc.Change_GBaHour) END AS HoursTillFull
		FROM @Results_Combined rc
		    JOIN dba.vw_DriveSpace_MostRecent mr
		        ON mr.Drive = rc.Drive;
		RETURN;
END
GO
