SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************************************************************************************************************
Name: dba.DriveSpace_Get_Data
Creation Date: 05.01.2024
Author: CPearson

Description:Retrive the drive space information 

******************************************************************************************************************************************************/
CREATE or alter  procedure [dba].[DriveSpace_Get_Data] 
AS
BEGIN
	     DECLARE
	          @ErrorSeverity INT
	          ,@ErrorMessage VARCHAR(MAX) ;
	begin try
	declare @HostInfo table 
	(
		OS nvarchar(256),
		Edition_Distribution nvarchar(256),
		Release nvarchar(256),
		Service_Pack_Level nvarchar(256),
		sku int,
		OS_Language_Version int,
		Architecture nvarchar(256)
		);


		
	insert into @HostInfo
	exec ('select * from sys.dm_os_host_info'); 

	end try
	begin catch
		if ERROR_NUMBER() = 208
		begin
			/*DM does not exist, that means we are on version <2017 which only supported windows*/
			insert into @HostInfo (OS)
			values('Windows'); 
		end else
		begin
			/*Unknown error*/
	     SELECT
	          @ErrorSeverity = error_severity()
	          ,@ErrorMessage = object_schema_name(@@procid)+'.'+object_name(@@procid) +' '+ 'Errored:' +' '+ error_message()
	
	     RAISERROR ( @ErrorMessage, @ErrorSeverity, 1 )
		end

	end catch
	BEGIN TRY	
SET XACT_ABORT ON;  
	
	select distinct
	@@SERVERNAME as ServerName,
   HostInfo.OS,
	DB_NAME(mf.database_id) AS DatabaseName,
	mf.[type_desc] as FileType,mf.physical_name,
	vs.*,
	case HostInfo.OS
		when 'Windows'
			then ISNULL(
						vs.volume_mount_point,
						LEFT(mf.physical_name,CHARINDEX('\', mf.physical_name,1))
						)
		when 'Linux'
			then LEFT(mf.physical_name,CHARINDEX('/', mf.physical_name,1))
		end
	from [master].sys.master_files AS mf
	cross apply (select * from @HostInfo) HostInfo
	cross apply [master].sys.dm_os_volume_stats(mf.database_id, mf.file_id) vs;

	exec sp_spaceused @oneresultset = 1
	END TRY
	BEGIN CATCH
	     SELECT
	          @ErrorSeverity = error_severity()
	          ,@ErrorMessage = object_schema_name(@@procid)+'.'+object_name(@@procid) +' '+ 'Errored:' +' '+ error_message()
	
	     RAISERROR ( @ErrorMessage, @ErrorSeverity, 1 )
	END CATCH
END


GO
