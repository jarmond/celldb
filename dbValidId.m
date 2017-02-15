function tf=dbValidId(table,id)
% DBVALIDID Checks if ID is valid.

conn = dbOpen();
sql = sprintf('SELECT 1 FROM %s WHERE id = %d',table,id);
results = fetch(conn.conn,sql);
tf = ~isempty(results);
