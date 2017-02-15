function dbAddMicroscope(name)
% Add microscope to db.


conn = dbOpen();
sql = ['INSERT INTO microscope (name) VALUES (''' name ''');'];
dbCheck(exec(conn.conn, sql));
