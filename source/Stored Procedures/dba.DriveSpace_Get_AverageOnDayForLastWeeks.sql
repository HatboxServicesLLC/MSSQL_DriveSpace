SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  OR ALTER procedure [dba].[DriveSpace_Get_AverageOnDayForLastWeeks] 
(
/*---------------------------------------
--External Variable Declaration
---------------------------------------*/
@Date DATETIME,
@NumWeeksBack TINYINT,
@DriveLetters nvarchar(125) NULL,
@Version NVARCHAR(12) = '1.0.0' OUTPUT/*[MAJOR].[MINOR].[BUG]*/
/*---------------------------------------
---------------------------------------*/
)
AS
BEGIN
	BEGIN TRY	
	/*validation*/
	--DriveLetters is comma delimited list
	/*--------------------------------------
	--Internal Variable Declaration
	--------------------------------------*/
	 
	
	-- << begin code logic >> --
		/* Averaged over Period*/
		SELECT v.Drive,
		       v.Drive_Letter,
		       --v.DriveTotalSpace_GB,
			   --CONVERT(DATE,v.CapturedDateTime) AS CapturedDate,
		       SUM(v.Change_GBaSecond) / COUNT(*) AS Sum_Change_GBaSecond,
		       SUM(v.Change_GBaMinute) / COUNT(*) AS Change_GBaMinute,
		       SUM(v.Change_GBaHour) / COUNT(*) AS Change_GBaHour
		FROM dba.vw_DriveSpace_Rates v
		WHERE (DATEPART(day,v.CapturedDateTime) = DATEPART(DAY,@Date)
				AND v.CapturedDateTime BETWEEN DATEADD(WEEK,-@NumWeeksBack,@Date) AND @Date)
			AND (@DriveLetters IS NULL 
					OR v.Drive_letter IN (SELECT value FROM STRING_SPLIT(@DriveLetters,',') drives))
		GROUP BY v.Drive,
		         v.Drive_Letter
		         --v.DriveTotalSpace_GB,
				 --,CONVERT(DATE,v.CapturedDateTime)
				 ;
	-- << end code logic >> --
	END TRY
	BEGIN CATCH
	     DECLARE
	          @ErrorSeverity INT
	          ,@ErrorMessage VARCHAR(MAX) ;
	     SELECT
	          @ErrorSeverity = error_severity()
	          ,@ErrorMessage = object_schema_name(@@procid)+'.'+object_name(@@procid) +' '+ 'Errored:' +' '+ error_message()
	
	     RAISERROR ( @ErrorMessage, @ErrorSeverity, 1 )
	END CATCH
END


GO
