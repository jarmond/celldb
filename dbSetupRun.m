function dbSetupRun(varargin)
% Creates a run and associated tasks using a model on experimental data. All
% parameters optional and specified as string-value pairs, any missing will be
% queried.
%
% Permissible arguments:-
%    'priors' : struct with priors as fields e.g. P.L=[0.2 0.01]; P.k=[10 1];
%               or priors encoded in string e.g. 'L=[0.2 0.01];k=[10 1];'
%               See dbGetDefaultPriors.
%    'model'  : string, model name or id
%    'data'   : index of experimental data to run on
%    'user'   : user initials or id
%    'name'   : name of run
%    'rc'     : Rc convergence diagnostic threshold, default 1.2;
%    'maxruns' : maximum number of chain extensions to improve convergence,
%    default 5:
%    'subset' : subset to specified cells - specify as indexes of trajData
%    struct.
%    'options': string, extra options to pass to model, specified as
%    assignments split by semicolons. E.g. 'projectionon=1;vpluszero=1;'
%    'initparams': vector of initial values for parameters. See dbGetDefaultInitParams.
%    'randominit': perturbation of initial values - 'overdispersed','gaussian','uniform','none'.
%                  default 'overdispersed'.
%    'singletrajtasks': set to zero to disable single trajectory per task, i.e. whole cell.
%                       default 1.
% jwa: 6/15

opts.priors=[];
opts.model=[];
opts.data=[];
opts.user=[];
opts.name=[];
opts.subset=[];
opts.options='';
opts.rc=1.2;
opts.maxruns=5;
opts.initparams=[];
opts.randominit='overdispersed';
opts.singletrajtasks=1;
opts = processOptions(opts,varargin{:});

% Replace spaces with _ in name.
opts.name = canonicalName(opts.name);

if isempty(opts.name)
  def = ['Unnamed run ' dbGuessUser()];
  opts.name = input(['No name specified. Enter name [default: ' def ']'],'s');
  if isempty(opts.name)
    opts.name = def;
  end
end

if isempty(opts.model)
  dbShowModels();
  opts.model = input('Choose model:');
end

% Convert model to id.
if ~isscalar(opts.model)
  opts.model = dbGetId('model','name',opts.model);
  if opts.model == 0
    error(['Unknown model:' opts.model]);
  end
end
if opts.model == 2
  disp('Reruns not supported for 1D harmonic well model. Setting maxruns=1.');
  opts.maxruns=1;
end


if isempty(opts.priors)
  disp('No priors specified. Using defaults for this model.');
  opts.priors = dbGetDefaultPriors(opts.model);
  disp(opts.priors);
end

% If prior struct, encode as string.
if isstruct(opts.priors)
  % Add missing fields, if applicable.
  defPriors = dbGetDefaultPriors(opts.model);
  opts.priors = structCopyMissingFields(opts.priors, defPriors);

  fields = fieldnames(opts.priors);
  priorStr = [];
  for i=1:length(fields)
    priorStr = [priorStr fields{i} '=' mat2str(opts.priors.(fields{i})) ';'];
  end
else
  priorStr = opts.priors;
end

% Query for missing parameters.
if isempty(opts.user)
  % Guess user from login.
  opts.user = dbGuessUser();
  if isempty(opts.user)
    % Still don't know.
    dbShowUsers();
    opts.user = input('Enter your user id or initials:');
  end
end

if isempty(opts.data)
  dbShowExperiments();
  opts.data = input('Choose data:');
end

if ~isscalar(opts.data)
  error('Data must be a single id');
end

% Convert user to id.
if ~isscalar(opts.user)
  opts.user = dbGetId('user','initials',opts.user);
  if opts.user == 0
    error(['Unknown user:' opts.user]);
  end
end

if isempty(opts.initparams)
  opts.initparams = mat2str(dbGetDefaultInitParams(opts.model));
end

% Add run to db.
conn = dbOpen();

% If run name exists, add the timestamp to make unique.
sql = ['SELECT 1 FROM run WHERE name = ''' opts.name ''';'];
results = table2cell(fetch(conn.conn, sql));
if ~isempty(results)
  error('Run name not unique.');
  %sql = 'SELECT unix_timestamp();';
  %results = fetch(conn.conn, sql);
  %stamp = num2str(results{1});
  %warning('Run name not unique. Suffixing with %s',stamp);
  %opts.name = [opts.name ' ' stamp];
end

sql = sprintf(['INSERT INTO run (name,user_id,experiment_id,model_id,priors,'...
               'extra_options,conv_Rc,maxruns,initparams,randominit) '...
               'VALUES (' interpString('sdddssddss') ');'],...
              opts.name,opts.user,opts.data,opts.model,priorStr,opts.options,...
              opts.rc,opts.maxruns,opts.initparams,opts.randominit);
dbCheck(exec(conn.conn, sql));

run_id = lastInsertId();
% Create tasks.
dbMakeTask(conn.conn,run_id,opts.data,opts.subset,opts.singletrajtasks);
if ~isempty(opts.subset)
  fprintf('Subsetting to trajData(%s)\n',num2str(opts.subset));
end
fprintf('Run created: %d\n',run_id);

  function id=lastInsertId()
  global dbsystem;

  switch dbsystem
    case 'sqlite'
      result = table2cell(fetch(conn.conn, 'SELECT last_insert_rowid();'));
    case 'mysql'
      result = table2cell(fetch(conn.conn, 'SELECT last_insert_id();'));
  end
  id = result{1};

  end

end
