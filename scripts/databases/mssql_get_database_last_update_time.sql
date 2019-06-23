DECLARE @script VARCHAR(MAX)
DECLARE @dbname SYSNAME  
 
DECLARE db_cursor CURSOR FOR  
SELECT d.name
  FROM MASTER.sys.databases d
JOIN [master].sys.server_principals sp
ON d.owner_sid = sp.[sid]
WHERE (d.name like 'tmp%'
 or d.name like '%tmp'
 or d.name like '%__tmp__%' escape '_')
 AND d.owner_sid in (
  SELECT sid FROM [master].sys.server_principals sp
  WHERE sp.name=REPLACE(SUSER_SNAME(), 'domain\', '')
 OR sp.name='domain\' + REPLACE(SUSER_SNAME(), 'domain\', ''))
 
OPEN db_cursor   

FETCH NEXT FROM db_cursor INTO @dbname   

SET @script = ''

WHILE @@FETCH_STATUS = 0 
BEGIN  
   if @script = ''
   SET @script = 'SELECT ''' + @dbname + ''' as DBName,
   (SELECT suser_sname( owner_sid ) FROM sys.databases
   WHERE name=''' + @dbname + ''') as DBOwner,
   (SELECT create_date FROM sys.databases
   WHERE name=''' + @dbname + ''') as CreateDate,
   MAX(t.modify_date) as LastUpdate
FROM ['+@dbname+'].sys.all_objects t
'
 else
 SET @script = @script + ' UNION ALL SELECT ''' + @dbname + ''' as DBName,
 (SELECT suser_sname( owner_sid ) FROM sys.databases
    where name=''' + @dbname + ''') as DBOwner,
 (SELECT create_date FROM sys.databases
   WHERE name=''' + @dbname + ''') as CreateDate,
    MAX(t.modify_date) as LastUpdate
FROM ['+@dbname+'].sys.all_objects t
'
FETCH NEXT FROM db_cursor INTO @dbname   
 
END 
SET @script = @script + 'ORDER BY DBName'
exec (@script) 

CLOSE db_cursor   
DEALLOCATE db_cursor