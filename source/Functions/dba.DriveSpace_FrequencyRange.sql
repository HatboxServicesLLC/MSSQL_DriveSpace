SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE OR ALTER function [dba].[DriveSpace_FrequencyRange] 
(
/*---------------------------------------
--External Variable Declaration
---------------------------------------*/
	@Frequency_Value int, 
	@Frequency_TimePart nvarchar(10),
	@GivenDate datetime,
	@Version NVARCHAR(12) = '1.0.0' OUTPUT/*[MAJOR].[MINOR].[BUG]*/

/*---------------------------------------
---------------------------------------*/
)
RETURNS @ResultSet TABLE(
			Frequency_Value int, 
			Frequency_DateTime nvarchar(10),
			GivenDate DATETIME,
			RangeStart DATETIME, 
			RangeEnd DATETIME
)
AS
BEGIN	
	/*--------------------------------------
	--Internal Variable Declaration
	--------------------------------------*/
		INSERT INTO @ResultSet
		SELECT 
		@Frequency_Value,
		@Frequency_TimePart,
		@GivenDate,
		CASE @Frequency_TimePart
			WHEN 'years'
				THEN DATEADD(YEAR,-@Frequency_Value, @GivenDate)
			WHEN 'months'
				THEN DATEADD(MONTH,-@Frequency_Value, @GivenDate)
			WHEN 'weeks'
				THEN DATEADD(WEEK,-@Frequency_Value, @GivenDate)
			WHEN 'days'
				THEN DATEADD(DAY,-@Frequency_Value, @GivenDate)
			WHEN 'hours'
				THEN DATEADD(HOUR,-@Frequency_Value, @GivenDate)
			WHEN 'minutes'
				THEN DATEADD(MINUTE,-@Frequency_Value, @GivenDate)
			WHEN 'seconds'
				THEN DATEADD(SECOND,-@Frequency_Value, @GivenDate)
		END,
		CASE @Frequency_TimePart
			WHEN 'years'
				THEN DATEADD(YEAR,@Frequency_Value, @GivenDate)
			WHEN 'months'
				THEN DATEADD(MONTH,@Frequency_Value, @GivenDate)
			WHEN 'weeks'
				THEN DATEADD(WEEK,@Frequency_Value, @GivenDate)
			WHEN 'days'
				THEN DATEADD(DAY,@Frequency_Value, @GivenDate)
			WHEN 'hours'
				THEN DATEADD(HOUR,@Frequency_Value, @GivenDate)
			WHEN 'minutes'
				THEN DATEADD(MINUTE,@Frequency_Value, @GivenDate)
			WHEN 'seconds'
				THEN DATEADD(SECOND,@Frequency_Value, @GivenDate)
		END
	RETURN;
END
GO
