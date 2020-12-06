function rows=dbSQL(sql)
% DBSQL Execute arbitary SQL. Potentially dangerous...

conn = dbOpen();
rows = table2cell(fetch(conn.conn,sql));
