SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************************************************************************************************************
Name: dbaTest_Load.Insert_DriveSpaceHistory
Creation Date: 03.13.2024
Author: CPearson

Description:Insert Records into DriveSpaceHistory table for testing. 

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
03.13.2024 CPearson        1                      0     			DO-2713		Initial stored procedure

Test Case:
-------------
- **this section should include detailed instructions of how to test the intended functionality of this stored procedure**

******************************************************************************************************************************************************/
CREATE   PROCEDURE [dbaTest_Load].[Insert_DriveSpaceHistory] 
(
/*---------------------------------------
--External Variable Declaration
---------------------------------------*/
@Drive nvarchar(260),
		    @DriveLetter nvarchar(10), 
		    @DriveTotalSpace_GB decimal(38, 4), 
		    @DriveFreeSpace_GB decimal(38, 4),
		    @Drive_UsedPrecentage decimal(38, 4),
		    @CapturedDateTime  datetime
/*---------------------------------------
---------------------------------------*/
)
AS
BEGIN
	BEGIN TRY
	
	/*--------------------------------------
	--Internal Variable Declaration
	--------------------------------------*/
				INSERT INTO dba.DriveSpaceHistory
				(
				    Drive,
				    Drive_Letter,
				    DriveTotalSpace_GB,
				    DriveFreeSpace_GB,
				    Drive_UsedPrecentage,
				    CapturedDateTime
				)
				VALUES
				(   @Drive, -- Drive - nvarchar(260)
				    @DriveLetter, -- Drive_Letter - nvarchar(10)
				    @DriveTotalSpace_GB, -- DriveTotalSpace_GB - decimal(38, 4)
				    @DriveFreeSpace_GB , -- DriveFreeSpace_GB - decimal(38, 4)
				    @Drive_UsedPrecentage, -- Drive_UsedPrecentage - decimal(38, 4)
				    @CapturedDateTime  -- CapturedDateTime - datetime
				    )
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
