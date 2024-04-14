SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************************************************************************************************************
Name: dba.DriveSpace_Alerting
Creation Date: 03.25.2024
Author: CPearson

Description:snd Drive space alers 


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
CREATE   PROCEDURE [dba].[DriveSpace_Alerting]
(
    /*---------------------------------------
    --External Variable Declaration
    ---------------------------------------*/
    @JobName sysname = NULL,
    @EmailTo NVARCHAR(100) = 'DBA_ITLowAlert@payspan.com;',
    @EmailFromProfile NVARCHAR(20) = 'DBA_IT'

/*---------------------------------------
---------------------------------------*/
)
AS
BEGIN
    BEGIN TRY
        /*--------------------------------------
        --Internal Variable Declaration
        --------------------------------------*/
        CREATE TABLE #AlertData (
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
            [FrequencyValue_TimePart] NVARCHAR(10),
            [CapturedWithinFrequency] INT
        );

        /*Retrive Estimates with Alert Indicator*/
        INSERT INTO #AlertData (
            RateBaseOn,
            Drive,
            Drive_Letter,
            Sum_Change_GBaSecond,
            Change_GBaMinute,
            Change_GBaHour,
            DriveSpaceHistory_id,
            DriveTotalSpace_GB,
            DriveFreeSpace_GB,
            Drive_UsedPrecentage,
            CapturedDateTime,
            SecondsTillFull,
            MinutesTillFull,
            HoursTillFull,
            ConfigName,
            ConfigEnabled,
            AlertConfig_Id,
            MinWithInHours,
            MaxWithInHours,
            DisplayMaxTimeAsTimePart,
            Color,
            FrequencyValue,
            FrequencyValue_TimePart
        )
        SELECT fn_ad.RateBaseOn,
               fn_ad.Drive,
               fn_ad.Drive_Letter,
               fn_ad.Sum_Change_GBaSecond,
               fn_ad.Change_GBaMinute,
               fn_ad.Change_GBaHour,
               fn_ad.DriveSpaceHistory_id,
               fn_ad.DriveTotalSpace_GB,
               fn_ad.DriveFreeSpace_GB,
               fn_ad.Drive_UsedPrecentage,
               fn_ad.CapturedDateTime,
               fn_ad.SecondsTillFull,
               fn_ad.MinutesTillFull,
               fn_ad.HoursTillFull,
               fn_ad.ConfigName,
               fn_ad.ConfigEnabled,
               fn_ad.AlertConfig_Id,
               fn_ad.MinWithInHours,
               fn_ad.MaxWithInHours,
               fn_ad.DisplayMaxTimeAsTimePart,
               fn_ad.Color,
               fn_ad.FrequencyValue,
               fn_ad.FrequencyValue_TimePart
        FROM dba.DriveSpace_AlertData(NULL, NULL) fn_ad;

        UPDATE ad
        SET CapturedWithinFrequency =
		case WHEN GETDATE() BETWEEN fqr.GivenDate AND  fqr.RangeEnd
		THEN 1
		else 0 
		END 
	
		--CASE ad.FrequencyValue_TimePart
  --                                        WHEN 'Months' THEN
  --                                            CASE WHEN DATEDIFF(MONTH, ad.[CapturedDateTime], GETDATE()) <= ad.[FrequencyValue] 
		--										THEN 1
  --                                              ELSE 0
  --                                            END
  --                                        WHEN 'Weeks' THEN 
		--									  CASE WHEN DATEDIFF(WEEK, ad.[CapturedDateTime], GETDATE()) <= ad.[FrequencyValue]  
		--										THEN 1
  --                                              ELSE 0
  --                                            END
  --                                        WHEN 'Days' THEN
  --                                            CASE WHEN DATEDIFF(DAY, ad.[CapturedDateTime], GETDATE()) <= ad.[FrequencyValue] 
		--										THEN 1
  --                                              ELSE 0
  --                                            END
  --                                        WHEN 'Hours' THEN
  --                                            CASE WHEN DATEDIFF(HOUR, ad.[CapturedDateTime], GETDATE()) <= ad.[FrequencyValue]  
		--										THEN 1
  --                                              ELSE 0
  --                                            END
  --                                        WHEN 'Minutes' THEN
  --                                            CASE WHEN DATEDIFF(MINUTE, ad.[CapturedDateTime], GETDATE()) <= ad.[FrequencyValue] 
		--										THEN 1
  --                                              ELSE 0
  --                                            END
  --                                        ELSE 0
  --                                    END
        FROM #AlertData ad
		OUTER APPLY dba.DriveSpace_FrequencyRange(FrequencyValue,FrequencyValue_TimePart,CapturedDateTime) fqr;

        /*Validate there is something to report*/
        IF EXISTS (SELECT * FROM #AlertData ad WHERE ad.AlertConfig_Id IS NOT NULL)
        BEGIN

            /*validate that captured within freq period*/
            IF ( SELECT MAX(CapturedWithinFrequency)FROM #AlertData ad) = 0
            BEGIN
                /*history out of date*/
                DECLARE @StaleDriveSpaceHistory_Subject NVARCHAR(300)
                    = N'The Drive Space History data is outdated on server ' + @@SERVERNAME,
                        @SinceLastOudatedEmail SMALLINT = 8,
                        @body NVARCHAR(MAX) = N'Apears that the DriveSpace History is outdated. Please research as there is a potention drive space issue.';

                /*Validate message hasn't already been sent within the last x hours*/
                IF NOT EXISTS ( SELECT 1
								FROM dba.DriveSpace_AlertEmailHistory aeh
								WHERE aeh.SubjectLine = @StaleDriveSpaceHistory_Subject
									  AND DATEDIFF(HOUR, aeh.SentDate, GETDATE()) < @SinceLastOudatedEmail)
                BEGIN
                    /*send email*/
                    EXEC msdb.dbo.sp_send_dbmail @profile_name = @EmailFromProfile,
                                                 @recipients = @EmailTo,
                                                 @subject = @StaleDriveSpaceHistory_Subject,
                                                 @body = @body,
                                                 @body_format = 'HTML';
                    /*UPdate email history table*/
                    INSERT INTO dba.DriveSpace_AlertEmailHistory (
                        DriveSpace_AlertLog_Id,
                        EmailTo,
                        EmailFromProfile,
                        SubjectLine,
                        Body,
                        SentDate
                    )
                    VALUES
                    (   NULL,                            -- DriveSpace_AlertLog_Id - int
                        @EmailTo,                        -- EmailTo - nvarchar(500)
                        @EmailFromProfile,               -- EmailFromProfile - nvarchar(300)
                        @StaleDriveSpaceHistory_Subject, -- SubjectLine - nvarchar(400)
                        @body,                           -- Body - nvarchar(max)
                        GETDATE()                        -- SentDate - datetime
                        );
                END;
                RETURN;

            END;

            /*TO DO , VERIFY MESSAGE HASN'T ALREADY BEEN SENT WITHIN FREQ PERIOD*/
            IF NOT EXISTS(SELECT 1
            FROM dba.DriveSpace_AlertEmailHistory aeh
                JOIN dba.DriveSpace_AlertLog al
                    ON aeh.DriveSpace_AlertLog_Id = al.id
                JOIN #AlertData ad
                    ON ad.AlertConfig_Id = al.AlertConfig_Id
                       AND ad.Drive_Letter = al.Drive_Letter
				CROSS APPLY dba.DriveSpace_FrequencyRange(ad.FrequencyValue, ad.FrequencyValue_TimePart, GETDATE()) fqr
			WHERE aeh.SentDate BETWEEN fqr.RangeStart AND fqr.GivenDate
			)
			BEGIN
				PRINT 'message already sent';
				RETURN;
			END


            /*create Email Body*/
            DECLARE @SubjectLine NVARCHAR(400);
            DECLARE @emailHeader NVARCHAR(MAX),
                    @tableHTML NVARCHAR(MAX);

            SET @emailHeader
                = N'
		<head>
		<style>
		table {
		  border-collapse: collapse;
		  width: 100%;
		}
		
		td, th {
		  border: 1px solid #dddddd;
		  text-align: left;
		  padding: 8px;
		  font-weight: bold;
		}
		
		tr:nth-child(even) {
		  background-color: #dddddd;  
		  border: 1px solid black;
		}
		.alert{	
		  font-weight: bold;
		}
		.red{
			color: #FF0000;
			background-color: #800000;
		}
		.orange{
			color: #FFA500;
			background-color: #D2691E;
		}
		.yellow{
			color: #FFFF00;
			background-color: #B8860B;
		}
		.green{
			color: #9ACD32;
			background-color: #2E8B57;
		}
		</style>
		</head>';
            SELECT @tableHTML = CONVERT(   NVARCHAR(MAX),
            (
                SELECT
            (
                SELECT 'Server: ' + @@SERVERNAME + ' Drive Space Alert (' + CONVERT(CHAR(11), GETDATE(), 113) + ')'
                FOR XML PATH(''), TYPE
            )       AS 'caption',
            (
                SELECT 'Rate Base On' AS th,
                       'Drive' AS th,
                       'Drive Letter' AS th,
                       'Sum Change GB a Second' AS th,
                       'Change GB a Minute' AS th,
                       'Change GB a Hour' AS th,
                       'Drive Space History Id' AS th,
                       'Drive Total Space GB' AS th,
                       'Drive Free Space GB' AS th,
                       'Drive Used Precentage' AS th,
                       'Captured Date Time' AS th,
                       'Seconds Till Full' AS th,
                       'Minutes Till Full' AS th,
                       'Hours Till Full' AS th,
                       'Config Name' AS th,
                       'Config Enabled' AS th,
                       'Alert Config Id' AS th,
                       'Min With In Hours' AS th,
                       'Max With In Hours' AS th,
                       'Display Max Time As Time Part' AS th,
                       'Color' AS th,
                       'Frequency Value' AS th,
                       'FrequencyValue_TimePart' AS th
                FOR XML RAW('tr'), ELEMENTS, TYPE
            ) AS 'thead',
            (
                SELECT [Drive] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [Drive_Letter] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [Sum_Change_GBaSecond] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [Change_GBaMinute] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [Change_GBaHour] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [DriveSpaceHistory_id] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [DriveTotalSpace_GB] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [DriveFreeSpace_GB] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [Drive_UsedPrecentage] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [CapturedDateTime] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [SecondsTillFull] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [MinutesTillFull] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [HoursTillFull] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [ConfigName] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [ConfigEnabled] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [AlertConfig_Id] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [MinWithInHours] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [MaxWithInHours] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [DisplayMaxTimeAsTimePart] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [Color] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [FrequencyValue] AS td,
                       '' AS [*], --hack to allow the use of PATH,
                       [FrequencyValue_TimePart] AS td
                FROM #AlertData ad
                ORDER BY CASE ad.Color
                             WHEN 'RED' THEN
                                 1
                             WHEN 'ORANGE' THEN
                                 2
                             WHEN 'YELLOW' THEN
                                 3
                             WHEN 'GREEN' THEN
                                 4
                             ELSE
                                 5
                         END ASC,
                         ad.Drive_Letter
                FOR XML PATH('tr'), ELEMENTS, TYPE
            ) AS 'tbody'
                FOR XML PATH(''), ROOT('table')
            )
                                       );
            SET @tableHTML
                = CONCAT(
                            @emailHeader,
                            @tableHTML,
                            '<hr>',
                            '<hr>',
                            '<div>',
                            'To see captured history query; ',
                            '<pre>',
                            '<code>',
                            'SELECT * FROM master.dba.DriveSpaceHistory',
                            '</code>',
                            '</pre>',
                            '</div>',
                            '<hr>',
                            '<hr>',
                            '<div>To see add a custom ''Alert at %''; INSERT/UPDATE master.dbo.dba_DriveSpaceAlertAt using the "Drive" from dba_DriveSpaceHistory<div>'
                        );
            /*Send Email*/
            EXEC msdb.dbo.sp_send_dbmail @profile_name = @EmailFromProfile,
                                         @recipients = @EmailTo,
                                         @subject = @JobName,
                                         @body = @tableHTML,
                                         @body_format = 'HTML';

            /*Update Log*/
            INSERT INTO dba.DriveSpace_AlertLog
            (
                RateBaseOn,
                Drive,
                Drive_Letter,
                Sum_Change_GBaSecond,
                Change_GBaMinute,
                Change_GBaHour,
                DriveSpaceHistory_id,
                DriveTotalSpace_GB,
                DriveFreeSpace_GB,
                Drive_UsedPrecentage,
                CapturedDateTime,
                SecondsTillFull,
                MinutesTillFull,
                HoursTillFull,
                ConfigName,
                ConfigEnabled,
                AlertConfig_Id,
                MinWithInHours,
                MaxWithInHours,
                DisplayMaxTimeAsTimePart,
                Color,
                FrequencyValue,
                FrequencyValue_TimePart,
                AlertLog_CreateDate
            )
            SELECT ad.RateBaseOn,
                   ad.Drive,
                   ad.Drive_Letter,
                   ad.Sum_Change_GBaSecond,
                   ad.Change_GBaMinute,
                   ad.Change_GBaHour,
                   ad.DriveSpaceHistory_id,
                   ad.DriveTotalSpace_GB,
                   ad.DriveFreeSpace_GB,
                   ad.Drive_UsedPrecentage,
                   ad.CapturedDateTime,
                   ad.SecondsTillFull,
                   ad.MinutesTillFull,
                   ad.HoursTillFull,
                   ad.ConfigName,
                   ad.ConfigEnabled,
                   ad.AlertConfig_Id,
                   ad.MinWithInHours,
                   ad.MaxWithInHours,
                   ad.DisplayMaxTimeAsTimePart,
                   ad.Color,
                   ad.FrequencyValue,
                   ad.FrequencyValue_TimePart,
                   GETDATE()
            FROM #AlertData ad;

        END;
    /*-- << end code logic >> --*/
    END TRY
    BEGIN CATCH
        DECLARE @ErrorSeverity INT,
                @ErrorMessage VARCHAR(MAX);
        SELECT @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorMessage
                   = OBJECT_SCHEMA_NAME(@@procid) + '.' + OBJECT_NAME(@@procid) + ' ' + 'Errored:' + ' '
                     + ERROR_MESSAGE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH;
END;
GO
