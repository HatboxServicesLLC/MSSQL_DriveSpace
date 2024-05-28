CREATE TABLE [dba].[DriveSpace_AlertConfig]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[ConfigName] [nvarchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreateDate] [datetime] NULL CONSTRAINT [DF__DriveSpac__Creat__05AEC38C] DEFAULT (getdate()),
[CreatedBy] [nvarchar] (1234) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConfigEnabled] [bit] NULL CONSTRAINT [DF__DriveSpac__Confi__06A2E7C5] DEFAULT ((0)),
[NotifyOperatorClass] [nvarchar] (350) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertConfig] ADD CONSTRAINT [PK_DriveSpace_AlertConfig_id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertConfig] ADD CONSTRAINT [UQ_DriveSpace_AlertConfig_ConfigName] UNIQUE NONCLUSTERED ([ConfigName]) ON [PRIMARY]
GO

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'TABLE', @level1name = N'DriveSpace_AlertConfig';
GO