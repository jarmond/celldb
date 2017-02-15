function dbAddModelSelAlg(name)
% Add model selection algorithm to db.

conn = dbOpen();
sql = sprintf(['INSERT INTO modelselalg (name) VALUES ('...
               interpString('s') ');'], name);
dbCheck(exec(conn.conn, sql));
