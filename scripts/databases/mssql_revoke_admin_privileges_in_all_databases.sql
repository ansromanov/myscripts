DECLARE @script VARCHAR(MAX)
DECLARE @dbname SYSNAME  
 
DECLARE db_cursor CURSOR FOR  
SELECT s.name
FROM master.sys.sysdatabases s
WHERE name NOT IN ('master','model','msdb','tempdb','ReportServer',
	'ReportServerTempDB')
	and s.name not like 'tmp%'
	and s.name not like '%tmp'
	and s.name not like '%__tmp__%' escape '_'
	and s.name not like 'test%'
	and s.name not like '%test'
	and s.name not like '%__old' escape '_'
	and s.name not like 'demo%'
	and s.name not like '%demo'

 
OPEN db_cursor   

FETCH NEXT FROM db_cursor INTO @dbname   

SET @script = ''

WHILE @@FETCH_STATUS = 0 
BEGIN  

	  PRINT @dbname
	  SET @script = '
use [' + @dbname + ']
'

	  select @script = @script + '
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE UPPER(name) = UPPER(N'''+name+''')) 
	CREATE USER ['+name+'] FOR LOGIN ['+name+']
ALTER ROLE [db_owner] DROP MEMBER ['+name+']
ALTER ROLE [db_securityadmin] DROP MEMBER ['+name+']
ALTER ROLE [db_datareader] ADD MEMBER ['+name+']
ALTER ROLE [db_datawriter] ADD MEMBER ['+name+']
	  '

	  from sys.sql_logins
	  WHERE name like ('usert%')

	  exec (@script)
      FETCH NEXT FROM db_cursor INTO @dbname   
	
END 

CLOSE db_cursor   
DEALLOCATE db_cursor