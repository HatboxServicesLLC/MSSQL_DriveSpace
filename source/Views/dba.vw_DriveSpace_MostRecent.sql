SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dba].[vw_DriveSpace_MostRecent]
AS 
SELECT RecentRecord.id,
       RecentRecord.Drive,
       RecentRecord.Drive_Letter,
       RecentRecord.DriveTotalSpace_GB,
       RecentRecord.DriveFreeSpace_GB,
       RecentRecord.Drive_UsedPrecentage,
       RecentRecord.CapturedDateTime
FROM
(
    SELECT ROW_NUMBER() OVER (PARTITION BY dsh.Drive_Letter ORDER BY dsh.CapturedDateTime DESC) AS MostRecent,
           *
    FROM dba.DriveSpaceHistory dsh
) AS RecentRecord
WHERE RecentRecord.MostRecent = 1;
GO
