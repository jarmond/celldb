function initials=dbShowUsers(user_id)
% Print list of users or return user initials.

conn = dbOpen();

sql = 'SELECT id,name,initials FROM user';
if nargin>0
  sql = [sql ' WHERE id=' num2str(user_id)];
else
  sql = [sql ';'];
end
results = fetch(conn.conn, sql);
results = table2cell(results);

if nargin>0
  initials = results{1,3};
else
  printHeader('Users');
  for i = 1:size(results,1)
    fprintf('%d: %s (%s)\n',results{i,:});
  end
end
