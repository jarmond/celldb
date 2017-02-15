function dbAddCellLine(name,desc)
% Add cell line to db.


conn = dbOpen();
sql = ['INSERT INTO cellline (name,description) VALUES (''' name ''',''' desc ''');'];
dbCheck(exec(conn.conn, sql));
