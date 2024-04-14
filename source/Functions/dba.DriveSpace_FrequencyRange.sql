SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************************************************************************************************************
Name: dba.DriveSpace_FrequencyRange
Creation Date: 03.25.2024
Author: CPearson

Description:for given frequency and date, determine start and end range . 


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
03.25.2024 CPearson        1                      0     			DO-2713		Initial stored procedure

Test Case:
-------------
- **this section should include detailed instructions of how to test the intended functionality of this stored procedure**

******************************************************************************************************************************************************/
CREATE function [dba].[DriveSpace_FrequencyRange] 
(
/*---------------------------------------
--External Variable Declaration
---------------------------------------*/
	@Frequency_Value int, 
	@Frequency_TimePart nvarchar(10),
	@GivenDate datetime

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
