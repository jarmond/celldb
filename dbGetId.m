function id=dbGetId(table,field,value)

conn = dbOpen();

sql = sprintf('SELECT id FROM %s WHERE %s LIKE ''%s''',table,field,value);
results = table2cell(fetch(conn.conn,sql));
if isempty(results)
  id = 0;
else
  id = results{1,1};
end
