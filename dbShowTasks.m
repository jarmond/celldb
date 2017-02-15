function dbShowTasks(runId,varargin)
% DBSHOWTASKS Print list of tasks.
%
%  dbShowTasks(runId,...)
%
% Show tasks for run with ID runId. Set runId to 0 to show all (default).
%
% Optional parameters as name/value pairs
% 'status' : string containing 'P' - pending, 'R' - running,% 'F' - finished, or
% 'A' for all. Default 'PR'.
% 'user' : user initials or id, default you. Set to 0 for all users.
% 'full' : show full list of tasks, default 0.


if nargin < 1
  runId = 0;
end

if runId > 0
  opts.status = 'A';
else
  opts.status = 'PR';
end
opts.user = dbGuessUser();
opts.full = 0;
opts = processOptions(opts,varargin{:});

opts.status = upper(opts.status);
if opts.full == 0
  opts.status = 'A';
end

conn = dbOpen();

sql = 'SELECT ';
% Just print counts.
if opts.full
  sql = [sql 'task.id,run.name,status,task.start,model.name,run.id,type,'...
         'trajdata_idx,task.finish,cell_idx,runcount,conv_Rc,sisterlist_idx,'...
         'convergence,maxruns '];
else
  sql = [sql 'count(*),status '];
end

sql = [sql 'FROM task '...
       'JOIN run ON run_id = run.id '...
       'JOIN experiment ON experiment_id = experiment.id '...
       'JOIN model ON model_id = model.id '...
       'JOIN user ON run.user_id = user.id '];

% Filter.
clauses = {};
if ~ismember('A',opts.status)
  statusClauses = arrayfun(@(x) ['status=''' x ''''],opts.status,'uniformoutput',false);
  clauses = [clauses ['(' strjoin(statusClauses,' OR ') ')']];
end
if runId > 0
  clauses = [clauses sprintf('run.id = %d',runId)];
end
if ischar(opts.user) || opts.user  ~= 0
  if ischar(opts.user)
    clauses = [clauses sprintf(['initials = ' interpString('s')],opts.user)];
  else
    clauses = [clauses sprintf('user.id = %d',opts.user)];
  end
end

if ~isempty(clauses)
  sql = [sql ' WHERE ' strjoin(clauses,' AND ')];
end

if ~opts.full
  sql = [sql ' GROUP BY status '];
end

% Order.
if opts.full
  sql = [sql ' ORDER BY task.id '];
else
  sql = [sql ' ORDER BY status '];
end

results = fetch(conn.conn, [sql ';']);
if isempty(results)
  fprintf('No tasks\n');
  return
end

if opts.full
  % Find convergence threshold.
  sql = sprintf('SELECT conv_Rc FROM run WHERE id=%d;',runId);
  convResults = fetch(conn.conn,sql);
  conv_Rc = convResults{1,1};
  if isempty(conv_Rc) || ~isfinite(conv_Rc)
    conv_Rc = 1.2;
    warning('Using default convergence threshold Rc=%f',conv_Rc);
  end

  typeStr = {'std','rerun','chib','sums'};
  disp('Tasks - P=pending,R=running,F=finished');
  printHeader('taskId[runId/cellIdx(trajdataIdx)slIdx] model: name | start->finish | runtype - status(iters/maxiters)');
  for i = 1:size(results,1)
    row = results(i,:);
    taskId = row{1};
    name = row{2};
    tstatus = row{3};
    start = row{4};
    model = row{5};
    runId = row{6};
    typeId = str2double(row{7});
    type = typeStr{typeId};
    trajdataIdx = row{8};
    finish = row{9};
    cellIdx = row{10};
    runcount = row{11};
    conv_Rc = row{12};
    sl_idx = row{13};
    convergence = row{14};
    maxruns = row{15};
    if isempty(convergence) || ~isfinite(convergence)
      isConv = '?';
    elseif convergence < conv_Rc
      isConv = 'Y';
    else
      isConv = 'N';
    end
    if typeId==1
      fprintf('%d[%d/%d(%d)/%d] %s: %s | %s->%s | %s - %s(%d/%d)\n',taskId,runId, ...
              cellIdx,trajdataIdx,sl_idx,model,name,start,finish,type,tstatus,runcount,maxruns);
    else
      fprintf('%d[%d/%d(%d)/%d] %s: %s | %s->%s | %s - %s\n',taskId,runId, ...
              cellIdx,trajdataIdx,sl_idx,model,name,start,finish,type,tstatus);
    end
  end
else
  for i=1:size(results,1)
    row = results(i,:);
    fprintf('Status %s: %d\n',row{2},row{1});
  end
end
