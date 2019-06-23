USE [msdb]
GO

/****** Object:  Job [differential_databases_backup]    Script Date: 14.10.2013 15:48:50 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 14.10.2013 15:48:50 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'differential_databases_backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'differential_databases_backup', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'domain\user', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup]    Script Date: 14.10.2013 15:48:50 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]

DECLARE @DatabaseFolder nvarchar(256)
SET @DatabaseFolder = ''D:\SQLBackups'' + ''\'' + CONVERT(varchar, sysdatetime(), 112) + ''\Diff'';
EXEC master.sys.xp_create_subdir @DatabaseFolder;

IF OBJECT_ID(''tempdb..#errors'') IS NOT NULL DROP TABLE #errors
GO
CREATE TABLE #errors(
  ID int PRIMARY KEY CLUSTERED IDENTITY( 1, 1),
  BaseName nvarchar(MAX),
  MSG nvarchar(MAX)
  )

if object_id(''tempdb..##tNamesDiff'') is not null
  drop table ##tNamesDiff

create table ##tNamesDiff(sTblName varchar(100))

declare @tNamesDiff table (Name nvarchar(1000))
insert @tNamesDiff
SELECT
    LTRIM( RTRIM( master.sys.databases.name))
  FROM master.sys.databases
  WHERE ''Demo,master,tempdb,model,msdb,ReportServer,ReportServerTempDB'' NOT LIKE ''%'' + master.sys.databases.name + ''%''
              and master.sys.databases.name not like ''tmp%''
              and master.sys.databases.name not like ''%tmp''

DECLARE
  @SQL nvarchar(MAX),
  @CurrentBase nvarchar(MAX),
  @Pos int,
  @C CURSOR
  
SET @C = CURSOR FOR SELECT Name from @tNamesDiff

OPEN @C

FETCH NEXT FROM @C INTO @CurrentBase
WHILE @@FETCH_STATUS = 0 BEGIN
insert ##tNamesDiff
values (@CurrentBase)

  SET @SQL = N''BACKUP DATABASE ['' + @CurrentBase + '']
TO
  DISK = N''''d:\SQLbackups\'' + CONVERT(varchar, sysdatetime(), 112) + ''\diff\'' +
  CONVERT(varchar, sysdatetime(), 112) + ''_'' + 
  '''' + @CurrentBase + '''' + ''_'' + REPLACE( CONVERT(varchar, sysdatetime(), 108), '':'', ''-'') + ''_diff.bak''''
WITH
  DIFFERENTIAL,
  COMPRESSION,
  NOFORMAT,
  NOINIT,
  NAME = N'''''' + @CurrentBase + '' backup'''',
  NOREWIND,
  NOUNLOAD,
  SKIP''

  BEGIN TRY
    PRINT ''Backup database ['' + @CurrentBase + '']'' + CHAR(13)
    EXEC( @SQL)
  END TRY
  BEGIN CATCH
    INSERT INTO #errors( BaseName, Msg)
    SELECT @CurrentBase, ERROR_MESSAGE()
  END CATCH
 
  FETCH NEXT FROM @C INTO @CurrentBase
END

CLOSE @C
DEALLOCATE @C

declare @sSQL varchar(4000)
set @sSQL=''bcp "SELECT * FROM ##tNamesDiff" queryout "d:\SQLLogs\''+ CONVERT(varchar, sysdatetime(), 112) + ''_'' + REPLACE( CONVERT(varchar, sysdatetime(), 108), '':'', ''-'')+''_diffbackup_list.txt" -T -c -t,''

EXEC xp_cmdshell @sSQL

if object_id(''tempdb..##tNamesDiff'') is not null
  drop table ##tNamesDiff


SELECT *
FROM #errors

IF OBJECT_ID(''tempdb..#errors'') IS NOT NULL DROP TABLE #errors

GO', 
		@database_name=N'master', 
		@output_file_name=N'd:\SQLLogs\BackupJobDiff.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'backup_every_3_hours', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=3, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130717, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'bc6e3baf-8226-4b28-8de2-23a9a87c1a44'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


