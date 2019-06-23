
USE [master]
SELECT name, principal_id, type_desc, is_disabled, create_date, modify_date,
       default_database_name 
FROM sys.server_principals
WHERE (sys.server_principals.is_disabled=1 
	AND (sys.server_principals.[type]='S' OR sys.server_principals.[type]='U')
	AND NAME NOT LIKE 'NT%')
ORDER BY type,name