CREATE TABLE [dba].[DriveSpaceHistory]
(
[id] [bigint] NOT NULL IDENTITY(1, 1),
[Drive] [nvarchar] (260) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Drive_Letter] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DriveTotalSpace_GB] [decimal] (38, 8) NULL,
[DriveFreeSpace_GB] [decimal] (38, 8) NULL,
[Drive_UsedPrecentage] [decimal] (38, 8) NULL,
[CapturedDateTime] [datetime] NULL
) ON [PRIMARY]
GO
DECLARE @xp bit
SELECT @xp=1
EXEC sp_addextendedproperty N'tSQLt.IsTempObject', @xp, 'SCHEMA', N'dba', 'TABLE', N'DriveSpaceHistory', NULL, NULL
GO
EXEC sp_addextendedproperty N'tSQLt.Private_TestDouble_OrgObjectName', N'tSQLt_tempobject_db2c155867e6464db8871d73a6038c14', 'SCHEMA', N'dba', 'TABLE', N'DriveSpaceHistory', NULL, NULL
GO
