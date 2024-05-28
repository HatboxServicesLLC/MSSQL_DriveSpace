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


EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'TABLE', @level1name = N'DriveSpaceHistory';
GO
