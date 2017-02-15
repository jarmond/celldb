function rows=dbSQL(sql)
% DBSQL Execute arbitary SQL. Potentially dangerous...

conn = dbOpen();
rows = fetch(conn.conn,sql);
