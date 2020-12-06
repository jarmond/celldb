function dbShowCellLines()
% Print list of cell lines

conn = dbOpen();

sql = 'SELECT id,name,code,description FROM cellline;';
results = fetch(conn.conn, sql);
results = table2cell(results);

if isempty(results)
  error('No cell lines');
else
  printHeader('Cell lines');
  for i = 1:size(results,1)
    fprintf('%d: %s (%s) - %s\n',results{i,:});
  end
end
