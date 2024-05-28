SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE OR ALTER  FUNCTION [dba].[DriveSpace_AlertData]
(
/*---------------------------------------
--External Variable Declaration
---------------------------------------*/
	@EndDate DATETIME = NULL,
	@DriveLetters NVARCHAR(500) = NULL
/*---------------------------------------
---------------------------------------*/
)
RETURNS @AlertDate TABLE 
(
    [RateBaseOn] VARCHAR(11),
    [Drive] NVARCHAR(260),
    [Drive_Letter] NVARCHAR(10),
    [Sum_Change_GBaSecond] DECIMAL(36, 8),
    [Change_GBaMinute] DECIMAL(36, 8),
    [Change_GBaHour] DECIMAL(36, 8),
    [DriveSpaceHistory_id] BIGINT,
    [DriveTotalSpace_GB] DECIMAL(38, 8),
    [DriveFreeSpace_GB] DECIMAL(38, 8),
    [Drive_UsedPrecentage] DECIMAL(38, 8),
    [CapturedDateTime] DATETIME,
    [SecondsTillFull] DECIMAL(38, 6),
    [MinutesTillFull] DECIMAL(38, 6),
    [HoursTillFull] DECIMAL(38, 6),
    [ConfigName] NVARCHAR(120),
    [ConfigEnabled] BIT,
    [AlertConfig_Id] INT,
    [MinWithInHours] INT,
    [MaxWithInHours] INT,
    [DisplayMaxTimeAsTimePart] NVARCHAR(10),
    [Color] NVARCHAR(10),
    [FrequencyValue] INT,
    [FrequencyValue_TimePart] NVARCHAR(10)
)
AS
BEGIN
	/*--------------------------------------
	--Internal Variable Declaration
	--------------------------------------*/
	 
	

		DECLARE @Estimations TABLE 
		(
		    [RateBaseOn] VARCHAR(11),
		    [Drive] NVARCHAR(260),
		    [Drive_Letter] NVARCHAR(10),
		    [Sum_Change_GBaSecond] DECIMAL(36, 8),
		    [Change_GBaMinute] DECIMAL(36, 8),
		    [Change_GBaHour] DECIMAL(36, 8),
		    [DriveSpaceHistory_id] BIGINT,
		    [DriveTotalSpace_GB] DECIMAL(38, 8),
		    [DriveFreeSpace_GB] DECIMAL(38, 8),
		    [Drive_UsedPrecentage] DECIMAL(38, 8),
		    [CapturedDateTime] DATETIME,
		    [SecondsTillFull] DECIMAL(38, 6),
		    [MinutesTillFull] DECIMAL(38, 6),
		    [HoursTillFull] DECIMAL(38, 6)
		);
		
		INSERT INTO @Estimations
		SELECT * 
		FROM dba.DriveSpace_EstimateWhenFull (@EndDate, @DriveLetters);
		
		INSERT INTO @AlertDate 
		SELECT est.*,
		       AlertConfigs.ConfigName,
		       AlertConfigs.ConfigEnabled,
		       AlertConfigs.AlertConfig_Id,
		       AlertConfigs.MinWithInHours,
		       AlertConfigs.MaxWithInHours,
		       AlertConfigs.DisplayMaxTimeAsTimePart,
		       ISNULL(AlertConfigs.Color, 'Green') AS Color,
		       AlertConfigs.FrequencyValue,
		       AlertConfigs.FrequencyValue_TimePart
		FROM @Estimations est
		    LEFT JOIN
		    (
		        SELECT ac.ConfigName,
		               ac.ConfigEnabled,
		               acv.Id,
		               acv.AlertConfig_Id,
		               LAG(acv.MaxWithInHours, 1, 0) OVER (PARTITION BY acv.AlertConfig_Id ORDER BY acv.MaxWithInHours) AS MinWithInHours,
		               acv.MaxWithInHours,
		               acv.DisplayMaxTimeAsTimePart,
		               acv.Color,
		               acv.FrequencyValue,
		               acv.FrequencyValue_TimePart
		        FROM [dba].[DriveSpace_AlertConfig] ac
		            JOIN [dba].[DriveSpace_AlertConfigValues] acv
		                ON ac.Id = acv.AlertConfig_Id
		    ) AlertConfigs
		        ON (
		               (
		                   (
		                       AlertConfigs.MinWithInHours = 0
		                       AND AlertConfigs.MinWithInHours <= est.HoursTillFull
		                   )
		                   OR (AlertConfigs.MinWithInHours < est.HoursTillFull)
		               )
		               AND est.HoursTillFull <= AlertConfigs.MaxWithInHours
		           );
		RETURN;
END
GO

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'FUNCTION', @level1name = N'DriveSpace_AlertData';
GO
