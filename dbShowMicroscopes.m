function dbShowMicroscopes()
% Print list of microscopes

conn = dbOpen();

sql = 'SELECT id,name FROM microscope;';
results = fetch(conn.conn, sql);
results = table2cell(results);
if isempty(results)
  error('No microscopes');
else
  printHeader('Microscopes');
  for i = 1:size(results,1)
    fprintf('%d: %s\n',results{i,:});
  end
end
