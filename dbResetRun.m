function dbResetRun(varargin)
% DBRESETRUN resets tasks of run to pending, to allow rerun.
%
% Pass options as name/value pairs.
%
% 'run' : runId to reset all tasks
% 'task' : taskId to reset single or list of tasks
% 'type' : limit to tasks of specific type (1: first run, 3: chib,
%          4: summary recompile), default 1.
% 'errors' : set to 1 to reset only tasks in error. default 0.
% 'dryrun' : set to 1 to visualize SQL statement without executing.
%
opts.run=[];
opts.task=[];
opts.type=1;
opts.errors=0;
opts.dryrun=0;
opts = processOptions(opts,varargin{:});

conn = dbOpen();

if ~isempty(opts.run) && ~isempty(opts.task)
  error('''run'' and ''task'' options mutually exclusive');
end

if isempty(opts.run) && isempty(opts.task)
  error('Must specify one of ''run'' or ''task''');
end

sql = 'UPDATE task SET status=''P'',start=NULL,finish=NULL,runcount=0,node=NULL,convergence=NULL,pbsid=NULL WHERE ';
if ~isempty(opts.run)
  % Reset whole run.
  sql = [sql sprintf('run_id=%d AND type=%d',opts.run,opts.type)];
elseif ~isempty(opts.task)
  taskIds = strjoin(arrayfun(@num2str,opts.task,'uniformoutput',false),',');
  sql = [sql sprintf('id in (%s)',taskIds)];
end

if opts.errors
  if opts.type > 1
    error(['Cannot use ''errors'' mode with Chib and summary tasks at this ' ...
           'time.']);
  end
  sql = [sql ' AND status=''E'''];
end

sql = [sql ';'];

if opts.dryrun
  disp(sql);
else
  dbCheck(exec(conn.conn,sql));
end
