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
ALTER TABLE [dba].[DriveSpace_AlertEmailHistory] ADD CONSTRAINT [PK__DriveSpa__3213E83FF1FD2CB2] PRIMARY KEY CLUSTERED ([id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_DriveSpace_AlertEmailHistory_Drive_Letter_SentDate] ON [dba].[DriveSpace_AlertEmailHistory] ([DriveSpace_AlertLog_Id]) INCLUDE ([SentDate]) ON [PRIMARY]
GO
ALTER TABLE [dba].[DriveSpace_AlertEmailHistory] ADD CONSTRAINT [fk_DriveSpace_AlertLog_Id] FOREIGN KEY ([DriveSpace_AlertLog_Id]) REFERENCES [dba].[DriveSpace_AlertLog] ([id])
GO
