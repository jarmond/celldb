function tf=dbUpdateTaskStatus(task_id,status,conditional,node)
% Returns true if update made.

if nargin<3
  conditional = [];
end
if nargin<4
  node = [];
end

conn = dbOpen();

if ~isempty(conditional)
  % Check current status, and only update if as specified.
  sql = sprintf('SELECT status FROM task WHERE id=%d;',task_id);
  results = fetch(conn.conn,sql);
  if results{1} ~= conditional
    tf=false;
    return;
  end
end

global dbsystem;
switch dbsystem
  case 'sqlite'
    now = 'datetime(''now'')';
  case 'mysql'
    now = 'now()';
end

fmt = ['UPDATE task SET status=''%s'''];
switch status
  case 'R'
    fmt = [fmt ',start=' now];
    if ~isempty(node)
      fmt = [fmt ',node=''' node ''''];
    end
  case {'F','E'}
    fmt = [fmt ',finish=' now];
end
fmt = [fmt ' WHERE id=%d LIMIT 1;'];
sql = sprintf(fmt,status,task_id);
dbCheck(exec(conn.conn,sql));
tf = true;

