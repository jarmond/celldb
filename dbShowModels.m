function dbShowModels()
% Print list of models

conn = dbOpen();

sql = 'SELECT id,name,description FROM model;';
results = fetch(conn.conn, sql);

printHeader('Models');
for i = 1:size(results,1)
  fprintf('%d: %s - %s\n',results{i,:});
end

