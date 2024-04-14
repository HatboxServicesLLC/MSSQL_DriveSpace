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
ALTER TABLE [dba].[DriveSpace_AlertConfigValues] ADD CONSTRAINT [PK__DriveSpa__3214EC07D02E2357] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertConfigValues] ADD CONSTRAINT [fk_AlertConfig_Id] FOREIGN KEY ([AlertConfig_Id]) REFERENCES [dba].[DriveSpace_AlertConfig] ([Id])
GO
