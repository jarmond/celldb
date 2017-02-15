function dbExecute(execmode,varargin)
% Executes pending tasks.
%
% Parameters:-
%    execmode: one of 'serial' for single MATLAB serial execution, 'batch'
%    for multiple MATLAB or 'pbs' to use the job management system, 'proc'
%    to use the process spawning batch executor.
%
%    runid: set to -1 to execute all runs, not just yours, or to a specific
%    run_id.
%
%    cores: number of cores to use. only valid in 'proc' mode.
%
%    quiet: be silent, default silent.


if nargin < 1
  execmode = 'serial';
end

params.runid = 0;
params.cores = 12;
switch execmode
  case {'batch','pbs'}
    params.quiet = 0;
  otherwise
    params.quiet = 1;
end
params.queue = 'private';
params.limit = 0; % number of jobs per run to queue at once. 0 = unlimited.
params.runlimit = 0; % number of runs to queue at once. 0 = unlimited.
params = processOptions(params,varargin{:});

runid = params.runid;
cores = params.cores;
quiet = params.quiet;

%nodes = {'node001','node002'}; % first should be the local host.
[~,node] = system('hostname -s');
node = strtrim(node);
if quiet<=0
  fprintf('Running on host %s\n',node);
end

if ~ismember(execmode,{'serial','batch','pbs','proc'})
  error('Invalid execmode');
end


% Run tasks.
global dbsystem;
switch execmode
  case 'pbs'
    % Find pending runs.
    runs = getRuns(runid==-1,runid,params.runlimit); % [id,maxruns]

    for i=1:size(runs,1)

      % Read task list.
      [tasks,types] = getTasks(runs(i,1),[],[],1,params.limit);
      idstr = arrayfun(@num2str,tasks,'uniformoutput',0);
      iddotstr = strjoin(idstr,'.');
      idcomstr = strjoin(idstr,',');
      maxruns = runs(i,2);
      % Estimate wall time needed.
      walltime = zeros(2,1);
      if any(ismember([1 3],types))
        % Empirical overestimate of time needed.
        walltime(1) = ceil((180+6*2^maxruns)/60);
      end
      if any(ismember([4 5 6],types))
        walltime(2) = 3; % hours.
      end
      walltime = max(walltime);

      % Submit tasks for this run as array job.
      fprintf('Submitting jobs for run %d\n',runs(i,1));
      cmd = sprintf('ssh nero ''qsub -q %s -N KDyn_%d -l walltime=%d:00:00 -t 0-%d -v TASKIDLIST="%s"'' < private/pbstemplate.pbs',params.queue,runs(i,1),walltime,length(tasks)-1,iddotstr);
      [status,result] = system(cmd);
      if status~=0
        fprintf('Error submitting PBS job: %s\n',result);
      end
      s = strfind(result,'[');
      if ~isempty(s)
        pbsid = str2double(result(1:s-1));
        updatePBSId(pbsid,idcomstr);
      end
    end

  case {'serial','batch'}
    % Read task list once and process.
    tasks = getTasks(runid,[],[],1);
    nTasks = size(tasks,1);

    for i=1:nTasks
      task_id = tasks(i);

      if strcmp(execmode,'serial')
        verb = 'Executing';
      else
        verb = 'Submitting';
      end
      if quiet<=0
        fprintf('%s task %d of %d (id %d)\n',verb,i,nTasks,task_id);
      end
      switch execmode
        case 'serial'
          dbExecuteTask(task_id);
        case 'batch'
          batchJob{i} = batch(@dbExecuteTask,0,{task_id,dbsystem});
        case 'pbs'
          cmd = sprintf('ssh nero ''qsub -q private -N KDyn_%d -v TASKID=%d'' < private/pbstemplate.pbs',task_id,task_id);
          [status,result] = system(cmd);
          if status~=0
            fprintf('Error submitting PBS job for task %d: %s\n',task_id,result);
          end
          s = strsplit(result,'.');
          if ~isempty(s)
            pbsid = str2double(s{1});
            updatePBSId(pbsid,task_id);
          end
      end

    end

    % Wait and clean up batch jobs.
    if strcmp(execmode,'batch')
      for i=1:length(batchJob)
        b = batchJob{i};
        wait(b);
        diary(b)
        delete(b);
      end
    end

  case 'proc'
    % Spawn tasks until all cores active, then poll until they
    % finish. Continue spawning until no pending tasks left.
    r = java.lang.Runtime.getRuntime;
    [~,maxprocs] = system('ulimit -u');
    maxprocs = str2double(maxprocs);

    while 1
      % Check number of processes (threads) against limits. Abort if excessive as a safety measure.
      [~,nprocs] = system('ps -L -u `whoami` | wc -l');
      nprocs = str2double(nprocs);
      if nprocs>0.9*maxprocs
        error('Too many processes running on system to safely continue %d/%d',nprocs,maxprocs);
      end

      % Get it twice, for some reason sometimes is empty first time....
      pending = getTasks(runid,'P');
      pending = getTasks(runid,'P');
      nTasks = size(pending,1);
      if quiet==0
        fprintf('%d tasks to execute\n',nTasks);
      elseif quiet<0
        fprintf('%d tasks to execute (Java heap status: %.1fMB free of %.1fMB (max %.1fMB)\n',nTasks,...
                r.freeMemory/1024^2,r.totalMemory/1024^2,r.maxMemory/1024^2);
      end
      if nTasks == 0
        if quiet<=0
          disp('Complete.');
        end
        return
      end

      % Find how many cores available, for this user.
      running = getTasks(0,'R',node);
      if quiet<=0
        fprintf('%d tasks currently running on %s\n',length(running), ...
                node);
      end
      unusedCores = cores - length(running);

      % Spawn that many task processes.
      for i=1:min(length(pending),unusedCores)
        task_id = pending(i);
        %cmd = sprintf(['screen -d -m matlab -nodesktop -singleCompThread
        %-r ' ...
        cmd = sprintf(['matlab -nodesktop -nosplash -singleCompThread -r ' ...
                       '"dbExecuteTask(' interpString('ds') ');" &'],task_id, ...
                      dbsystem);
        % if j~=1
        %   cmd = ['ssh -n -f ' nodes{j} ' cd ' pwd '; ' cmd];
        %   cmd = sqlEscape(cmd,'()''";'); % escape-fu for ssh
        %                                  %cmd = strrep(cmd,'''','''''');
        % end
        fprintf('Spawning MATLAB process for task %d on %s...\n',task_id,node);
        [status,result] = system(cmd);
        if status~=0
          fprintf('Error spawning process for task %d: %s\n',task_id,result);
        end
        % Sleep for a very short bit.
        pause(0.2);
      end
      % Request GC then sleep for a bit
      r.gc();
      pause(30);
    end

end

if quiet<=0
  disp('Complete.');
end

end

function runs=getRuns(allUsers,runid,limit)
  if nargin < 2 || isempty(runid) || runid<=0
    runid = [];
  end
  if nargin < 3 || isempty(limit)
    limit = 0;
  end

  % Get list of runs associated with tasks for PBS mode.
  conn = dbOpen();
  sql = 'SELECT DISTINCT run_id,maxruns FROM task JOIN run ON run_id=run.id ';
  if ~allUsers
    user = dbGuessUser();
    sql = [sql 'JOIN user ON user_id=user.id '];
  end
  sql = [sql 'WHERE status=''P'' AND pbsid IS NULL'];
  if ~allUsers
    sql = [sql sprintf([' AND initials=' interpString('s')],user)];
  end
  if ~isempty(runid)
    sql = [sql sprintf([' AND run_id=' interpString('d')],runid)];
  end
  sql = [sql ' ORDER BY run.id ASC'];
  if limit > 0
    sql = [sql ' LIMIT ' num2str(limit)];
  end
  sql = [sql ';'];
  results = fetch(conn.conn,sql);
  runs = cell2mat(results);
end

function [tasks,types]=getTasks(runid,status,node,pbs,limit)

  if nargin<2 || isempty(status)
    status = 'P';
  end
  if nargin<3 || isempty(node)
    node = [];
  end
  if nargin<4 || isempty(pbs)
    pbs = 0; % Check PBS ID is null, i.e. not already submitted.
  end
  if nargin<5 || isempty(limit)
    limit = 0;
  end

  % Get list of tasks.
  conn = dbOpen();

  sql = ['SELECT task.id,type FROM task '...
         'JOIN run ON run_id=run.id '];
  if runid == 0
    user = dbGuessUser();
    sql = [sql sprintf(['JOIN user ON user_id=user.id WHERE status=' ...
                        interpString('s') ' AND initials='...
                        interpString('s')],status,user)];
  elseif runid == -1
    sql = [sql sprintf(['WHERE status=' interpString('s')],status)];
  else
    sql = [sql sprintf(['WHERE status=' interpString('s') ' AND run_id=%d'],...
                       status,runid)];
  end
  if ~isempty(node)
    sql = [sql sprintf([' AND node=' interpString('s')],node)];
  end
  if pbs
    sql = [sql ' AND pbsid IS NULL'];
  end
  sql = [sql ' ORDER BY priority DESC,task.id ASC'];
  if limit > 0
    sql = [sql ' LIMIT ' num2str(limit)];
  end
  sql = [sql ';'];
  results = fetch(conn.conn,sql);

  tasks = cell2mat(results(:,1));
  if nargout>1
    types = cellfun(@str2double,results(:,2));
  end
end

function updatePBSId(pbsid,taskid)
  conn = dbOpen();
  sql = sprintf('UPDATE task SET pbsid=%d WHERE id in (%s);',pbsid,taskid);
  dbCheck(exec(conn.conn,sql));
end
