function dbDeleteRun(run_id,dryrun)
% Deletes run from DB.
%
%  DBDELETERUN(RUN_ID) to delete run
%    or
%  DBDELETERUN(RUN_ID,1) to show SQL statements as dry run.

if nargin<2
  dryrun=0;
end

% Check run exists and is owned by user.
user = dbGuessUser();

conn = dbOpen();

sql = sprintf(['SELECT run.name FROM run JOIN user ON user_id=user.id '...
               'WHERE initials=' interpString('s') ' AND run.id=%d;'],user, ...
              run_id);
results = fetch(conn.conn,sql);
if isempty(results)
  error('You have no run with id %d',run_id);
end
row = results(1);
run_name = row{1};

% Delete the run.
reply = input(['Really delete run ' run_name '? (y/n): '],'s');
if isempty(reply) || reply(1) ~= 'y'
  disp('Aborted.');
  return
end

sql = sprintf('DELETE FROM run WHERE id = %d;',run_id);
if dryrun
  disp(sql);
else
  dbCheck(exec(conn.conn,sql));
end

% Delete logs.
sql = sprintf(['DELETE FROM log USING log JOIN task WHERE task_id=task.id '...
               'AND run_id = %d;'],run_id);
if dryrun
  disp(sql);
else
  dbCheck(exec(conn.conn,sql));
end

% Delete tasks.
sql = sprintf('DELETE FROM task WHERE run_id = %d;',run_id);
if dryrun
  disp(sql);
else
  dbCheck(exec(conn.conn,sql));
end

% Delete run data.
global dbrunpath;
outpath = [dbrunpath filesep run_name];
cmd = ['rm -rf ' outpath];
if dryrun
  disp(cmd);
else
  system(cmd);
end

