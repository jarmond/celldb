function dbIncreasePriority(runId)
% DBINCREASEPRIORITY Increase priority of run

conn = dbOpen();

user=dbGuessUser();
sql = sprintf(['SELECT initials,priority FROM run JOIN user ON '...
               'user_id=user.id WHERE run.id=%d'],runId);
results = fetch(conn.conn,sql);
if isempty(results)
  error('No such run id %d',runId);
end
if ~strcmp(user,results{1,1})
  error('Run %d is not owned by you',runId);
end
priority = results{1,2};

sql = sprintf('UPDATE run SET priority=priority+1 WHERE id=%d',runId);
dbCheck(exec(conn.conn,sql));

fprintf('Priority for run %d increased from %d to %d\n',runId,priority,priority+1);

