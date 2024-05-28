CREATE TABLE [dba].[DriveSpace_AlertLog]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[RateBaseOn] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Drive] [nvarchar] (260) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Drive_Letter] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Sum_Change_GBaSecond] [decimal] (36, 8) NULL,
[Change_GBaMinute] [decimal] (36, 8) NULL,
[Change_GBaHour] [decimal] (36, 8) NULL,
[DriveSpaceHistory_id] [bigint] NULL,
[DriveTotalSpace_GB] [decimal] (38, 8) NULL,
[DriveFreeSpace_GB] [decimal] (38, 8) NULL,
[Drive_UsedPrecentage] [decimal] (38, 8) NULL,
[CapturedDateTime] [datetime] NULL,
[SecondsTillFull] [decimal] (38, 6) NULL,
[MinutesTillFull] [decimal] (38, 6) NULL,
[HoursTillFull] [decimal] (38, 6) NULL,
[ConfigName] [nvarchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConfigEnabled] [bit] NULL,
[AlertConfig_Id] [int] NULL,
[MinWithInHours] [int] NULL,
[MaxWithInHours] [int] NULL,
[DisplayMaxTimeAsTimePart] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Color] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FrequencyValue] [int] NULL,
[FrequencyValue_TimePart] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AlertLog_CreateDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertLog] ADD CONSTRAINT [PK_DriveSpace_AlertLog_id] PRIMARY KEY CLUSTERED ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_DriveSpace_AlertLog_Drive_Letter] ON [dba].[DriveSpace_AlertLog] ([Drive_Letter], [AlertConfig_Id]) INCLUDE ([CapturedDateTime], [AlertLog_CreateDate], [FrequencyValue], [FrequencyValue_TimePart]) ON [PRIMARY]
GO

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'TABLE', @level1name = N'DriveSpace_AlertLog';
GO
