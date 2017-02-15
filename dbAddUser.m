function dbAddUser(name,initials)
% Add user to db.

conn = dbOpen();
sql = sprintf(['INSERT INTO user (name,initials) VALUES ('...
               interpString('ss') ');'], name,initials);
dbCheck(exec(conn.conn, sql));
