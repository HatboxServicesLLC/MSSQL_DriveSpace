CREATE TABLE [dba].[DriveSpace_AlertConfigValues]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[AlertConfig_Id] [int] NULL,
[MaxWithInHours] [int] NULL,
[DisplayMaxTimeAsTimePart] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Color] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FrequencyValue] [int] NULL,
[FrequencyValue_TimePart] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertConfigValues] ADD CONSTRAINT [PK_DriveSpace_AlertConfigValues_id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertConfigValues] ADD CONSTRAINT [fk_DriveSpace_AlertConfigValues_AlertConfig_Id] FOREIGN KEY ([AlertConfig_Id]) REFERENCES [dba].[DriveSpace_AlertConfig] ([Id])
GO

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'TABLE', @level1name = N'DriveSpace_AlertConfigValues';
GO
