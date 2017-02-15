function runCount=dbIncrementRunCount(taskId,inc)
if nargin<2
  inc=1;
end

conn = dbOpen();
sql = sprintf('UPDATE task SET runcount=runcount+%d WHERE id=%d LIMIT 1;',inc,taskId);
dbCheck(exec(conn.conn,sql));

sql = sprintf('SELECT runcount FROM task WHERE id=%d;',taskId);
results = fetch(conn.conn,sql);
runCount = results{1,1};

