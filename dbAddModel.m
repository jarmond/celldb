function dbAddModel(name,desc)
% Add model to db.

if nargin<2
  desc='';
end

conn = dbOpen();
sql = sprintf(['INSERT INTO model (name,description) VALUES ('...
               interpString('ss') ');'],name,desc);
dbCheck(exec(conn.conn, sql));
