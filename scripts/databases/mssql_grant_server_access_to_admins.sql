USE master
DECLARE @script VARCHAR(MAX)
DECLARE @loginname SYSNAME  

DECLARE login_cursor CURSOR FOR  
SELECT name 
FROM master.sys.server_principals sp
WHERE sp.name in ('domain\user')
	 
OPEN login_cursor   
FETCH NEXT FROM login_cursor INTO @loginname   

SET @script = ''

WHILE @@FETCH_STATUS = 0 
BEGIN  
	PRINT @loginname
	  select @script =  @script + '
GRANT ALTER ANY CREDENTIAL TO ['+ @loginname +']
GRANT ALTER ANY LOGIN TO ['+ @loginname +']
GRANT CONTROL SERVER TO ['+ @loginname +']
	  '
	  FETCH NEXT FROM login_cursor INTO @loginname  
END 

PRINT @script
exec (@script)

CLOSE login_cursor   
DEALLOCATE login_cursor