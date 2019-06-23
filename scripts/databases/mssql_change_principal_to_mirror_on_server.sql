use master

declare @sSQL varchar(max)
declare @sDBName varchar(max)

declare crCursor cursor for
	select db.name 
	from sys.database_mirroring mir
	join sys.databases db on db.database_id=mir.database_id
	where mir.mirroring_state=4 and mir.mirroring_role=1
open crCursor

while 1=1
 begin
  fetch next from crCursor into @sDBName
  if @@FETCH_STATUS<>0 break

  set @sSQL='alter database ['+@sDBName+'] set partner failover'

  exec(@sSQL)
 end
close crCursor
deallocate crCursor