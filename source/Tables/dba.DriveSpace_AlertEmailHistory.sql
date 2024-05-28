CREATE TABLE [dba].[DriveSpace_AlertEmailHistory]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[DriveSpace_AlertLog_Id] [int] NULL,
[EmailTo] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailFromProfile] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SubjectLine] [nvarchar] (400) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Body] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SentDate] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertEmailHistory] ADD CONSTRAINT [PK_DriveSpace_AlertEmailHistory_id] PRIMARY KEY CLUSTERED ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_DriveSpace_AlertEmailHistory_DriveSpace_AlertLog_Id_incl_SentDate] ON [dba].[DriveSpace_AlertEmailHistory] ([DriveSpace_AlertLog_Id]) INCLUDE ([SentDate]) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertEmailHistory] ADD CONSTRAINT [fk_DriveSpace_AlertLog_Id] FOREIGN KEY ([DriveSpace_AlertLog_Id]) REFERENCES [dba].[DriveSpace_AlertLog] ([id])
GO

/*VERSION*/
EXEC sp_addextendedproperty @name = N'VERSION',
    @value = '1.0.0.0'/*[MAJOR].[MINOR].[SECURITY].[BUG]*/,
    @level0type = 'SCHEMA', @level0name = N'dba',
    @level1type = 'TABLE', @level1name = N'DriveSpace_AlertEmailHistory';
GO
