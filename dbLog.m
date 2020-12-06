function log=dbLog(taskId,quiet)
% DBLOG Print log from task
%
% taskId : ID of task with log
% quiet : Set to 1 to prevent echo to terminal
%
% jwa: 04/15

if nargin<2
  quiet = 0;
end

conn = dbOpen();
sql = sprintf('SELECT log FROM log WHERE task_id=%d;',taskId);

results = table2cell(fetch(conn.conn, sql));
if isempty(results)
  fprintf('No task with ID %d\n',taskId);
  return
end

log = results{1,1}
if ~quiet
  disp(log);
end
