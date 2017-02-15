function dbShowRuns(varargin)
% DBSHOWRUNS Print list of runs by status
%
% Optional parameters with name/value pairs:
%  'status' : 'P' - pending, 'R' - running', 'F' - finished, or 'A' for
%  all. Default 'A'.
%  'user' : user initial. Default you.
%  'run' : show detailed view of single run 

% Needs work - determine run status from tasks.

opts.status = 'A';
opts.user = dbGuessUser();
opts.run = [];
if nargin>0
  opts = processOptions(opts,varargin{:});
end
opts.status = upper(opts.status);

conn = dbOpen();

global dbrunpath dbdatapath

% If specific run, print details. Else list summaries.
if ~isempty(opts.run)
  params = {'run.name','Run name';
            'created','Creation time:';
            'experiment.name','Experiment name';
            'experiment.description','Experiment description';
            'experiment.date','Experiment date';
            'experiment.id','@Experiment ID';
            'cellline.name','Cell line';
            'num_cells','@Number of cells';
            'file','Data file';
            'model.name','Model';
            'numsteps','@Number of steps';
            'subsample','@Subsample interval';
            'burnin','@Burn-in';
            'numchains','@Number of chains';
            'priors','Priors';
            'conv_Rc','#Rc threshold';
            'maxruns','@Max run iterations';
            'extra_options','Extra options';
            'priority','@Priority'};
  sql = sprintf(['SELECT ' strjoin(params(:,1)',',') ...
                 ' FROM run JOIN experiment ON experiment_id=experiment.id ' ...
                 'JOIN model ON model_id=model.id '...
                 'JOIN cellline ON cellline_id=cellline.id WHERE run.id = %d;'], ...
                opts.run);
  results = fetch(conn.conn, sql);
  if isempty(results)
    fprintf('No run with ID %d\n',opts.run);
  else
    printHeader(sprintf('Info for run %d',opts.run));
    for i=1:size(params,1)
      desc = params{i,2};
      if desc(1) == '@'
        fprintf('%s: %d\n',desc(2:end),results{1,i});
      elseif desc(1) == '#'
        fprintf('%s: %f\n',desc(2:end),results{1,i});
      else
        fprintf('%s: %s\n',desc,results{1,i});
      end
    end
  end
  % Additional info.
  fprintf('Run directory: %s\n',fullfile(dbrunpath,results{1,1}));
  fprintf('Data file path: %s\n',fullfile(dbdatapath,results{1,9}));
  return
end

% Not single run. Print summaries.
sql = ['SELECT DISTINCT run.id,run.name,model.name '...
       'FROM run '...
       'JOIN model ON model_id = model.id ' ...
       'JOIN user ON user_id = user.id '];

% Filter.
clauses = {};
if opts.status ~= 'A'
  if opts.status == 'F'
    op = 'ALL';
  else
    op = 'ANY';
  end
  clauses = [clauses sprintf([interpString('s') ' = %s(SELECT opts.status '...
                     'FROM task WHERE run_id = run.id)'],opts.status,op)];
end

if ~isempty(opts.user)
  clauses = [clauses sprintf(['user.initials = ' interpString('s')], ...
                             opts.user)];
end

if ~isempty(clauses)
  sql = [sql ' WHERE ' strjoin(clauses,' AND ')];
end

% Order.
sql = [sql ' ORDER BY run.id;'];

results = fetch(conn.conn, sql);

if isempty(results)
  fprintf('No runs\n');
else
  switch opts.status
    case 'P'
      hdr = 'Pending runs';
    case 'A'
      hdr = 'All runs';
    case 'F'
      hdr = 'Finished runs';
    case 'R'
      hdr = 'Running runs';
  end
  hdr = [hdr ' for ' opts.user];
  printHeader(hdr);
  for i = 1:size(results,1)
    row = results(i,:);
    id = row{1};
    name = row{2};
    model = row{3};
    fprintf('%d %s: %s\n',id,name,model);
  end
end
