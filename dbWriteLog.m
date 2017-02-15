function dbWriteLog(task_id,log)

conn = dbOpen();

% Trim log to ensure doesn't exceed max_allowed_packet size.
maxLogSize = 1024 * 1000;
log = log(max(1,length(log)-maxLogSize):end);

sql = sprintf(['INSERT INTO log (task_id,log) VALUES ('...
              interpString('ds') ') ON DUPLICATE KEY UPDATE log=VALUES(log);'],task_id,sqlEscape(log));
dbCheck(exec(conn.conn, sql));
