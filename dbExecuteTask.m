function dbExecuteTask(task_id,dbsystem,verbose)

% If dbsystem specified, assume we run in fresh MATLAB instance, need to
% reinit db.
if nargin >= 2 && ~isempty(dbsystem)
  dbInit(dbsystem);
end

if nargin<3
  verbose = 0;
end

conn = dbOpen();

sql = sprintf(['SELECT model.name,run_id,file,run.name,numsteps,'...
       'subsample,burnin,numchains,priors,num_cells,trajdata_idx,paramnames,'...
       'initparams,priortypes,type,extra_options,runcount,conv_Rc,maxruns,'...
       'sisterlist_idx,randominit '...
       'FROM model '...
       'JOIN run ON model_id=model.id '...
       'JOIN task ON run_id=run.id '...
       'JOIN experiment ON experiment_id=experiment.id '...
       'WHERE task.id=%d;'],task_id);
results = fetch(conn.conn,sql);

row = results;
model_name = row{1};
run_id = row{2};
file = row{3};
run_name = row{4};
rundata.numsteps = row{5};
rundata.subsample = row{6};
rundata.burnin = row{7};
rundata.numchains = row{8};
priorStr = row{9};
numCell = row{10};
trajDataIdx = row{11};
paramnames = row{12};
initparams = row{13};
priortypes = row{14};
runType = row{15};
extraOpts = row{16};
runCount = row{17};
conv_Rc = row{18};
maxruns = row{19};
sisterlist_idx = row{20};
randominit = row{21};
% NB trajDataIdx here refers to the index into the trajData struct,
% not trajData(i).cellIdx.
assert(trajDataIdx <= numCell || runType>=5, 'Invalid trajDataIdx');

% Get priors in RunMCMC compatible struct.
rundata.priors = dbGetPriors(run_id);
rundata.priors.types = strsplit(priortypes,',');

% Load data.
global dbdatapath dbrunpath dbusemex;
absfile = fullfile(dbdatapath,file);
trajData = loadTrajData(absfile);
exptData = dbGetExptDat(absfile,trajData);
if trajDataIdx>0
  trajData = trajData(trajDataIdx);
end
if sisterlist_idx>0
  trajData.sisterList = trajData.sisterList(sisterlist_idx);
end

% Set up rundata.
rundata.paramnames = strsplit(paramnames,',');
rundata.randomiseinit=randominit;
rundata.randomisationerr=0.6;
rundata.randomisationExpand=10;
rundata.randomiseswtims=0;
rundata.init_hMC=[];
rundata.savdir=exptData.name;
rundata.initparams = str2num(initparams);
if isempty(dbusemex)
  rundata.usemex = 0;
else
  rundata.usemex = dbusemex;
end

% Process model options.
modoptions.compilecells = 0; % Compile works over multiple trajectories. Run separately.
assigns = strsplit(extraOpts,';');
for i=1:length(assigns)
  if ~isempty(assigns{i})
    s = strsplit(assigns{i},'=');
    try
      modoptions.(s{1}) = str2num(s{2});
      if isnan(modoptions.(s{1}))
        error('Invalid value');
      end
    catch
      warning('Failed to parse extra option: %s',assigns{i});
    end
  end
end

outpath = [dbrunpath filesep run_name];

[~,node] = system('hostname -s');
node = strtrim(node);

% Mark as running. Use transaction to avoid races with other nodes.
dbCheck(exec(conn.conn,'START TRANSACTION;'));
if dbUpdateTaskStatus(task_id,'R','P',node);
  dbCheck(exec(conn.conn,'COMMIT;'));
else
  dbCheck(exec(conn.conn,'ROLLBACK;'));
  fprintf('Task %d already running\n',task_id);
  return;
end

clear conn;

if trajDataIdx>0
  fprintf('Running on data %s\nCell %03d Trajectory %d\nStoring in %s\n',file,trajData.cellIdx,trajData.sisterList(1).idx,outpath);
else
  fprintf('Running on data %s\nRun ID %d\nStoring in %s\n',file,run_id,outpath);
end
try
  switch runType
    case '1'
      log=[];
      if runCount < 1 % First run.
        fprintf('Running model %s (first out of max %d iterations)...\n',model_name,maxruns);
        log=[log evalc('RunMCMC(trajData,model_name,rundata,exptData,outpath,0,modoptions);')];
        runCount = dbIncrementRunCount(task_id);
      end
      % Check convergence regardless so we know whether to ReRun.
      convergence = dbUpdateConvergence(task_id,run_id,trajData.cellIdx,cell2mat({trajData.sisterList.idx}));

      % Continue iterations if necessary.
      typ={2,1};
      conv_criteria.GR=conv_Rc;
      if sisterlist_idx == 0
        % Run whole cell ReRunMCMC
        repeats=maxruns-runCount; % How many remaining iterations to attempt?
        if repeats > 0
          fprintf('Running model %s (%d-%d iterations)...\n',model_name,runCount+1,maxruns);
          log=[log evalc(['ReRunMCMC(trajData,model_name,typ,conv_criteria,repeats,' ...
                          'exptData,outpath,0,modoptions);'])];
          runCount = dbIncrementRunCount(task_id,repeats);
          convergence = dbUpdateConvergence(task_id,run_id,trajData.cellIdx,trajData.sisterList.idx);
        end
      else
        % Run single traj ReRunMCMC
        isConverged = convergence < conv_Rc;
        while runCount < maxruns && ~isConverged
          % Single repeat until converged or maxruns exceeded.
          fprintf('Running model %s (iteration %d of max %d)...\n',model_name,runCount+1,maxruns);
          log=[log evalc(['ReRunMCMC_singletraj(trajData,model_name,typ,conv_criteria,1,' ...
                          'exptData,outpath,0,modoptions);'])];
          runCount = dbIncrementRunCount(task_id);
          convergence = dbUpdateConvergence(task_id,run_id,trajData.cellIdx,trajData.sisterList.idx);
          isConverged = convergence < conv_Rc;
        end

        if isConverged
          log = [log sprintf('Run converged after %d iterations\n',runCount)];
        else
          log = [log fprintf('Run remains unconverged after %d iterations\n',runCount)];
        end
      end

    case '2'
      error('type 2 tasks are no longer used');
    case '3'
      % Chib reduced distribution.
      fprintf('Running Chib reduced distributions...\n');
      log=evalc(['dbExecuteChib(trajData,model_name,rundata,exptData,' ...
                 'outpath,run_id)']);
    case '4'
      % Re-compile summaries.
      fprintf('Recompiling summaries...\n');
      log=evalc('dbExecuteSummary(trajData,model_name,exptData,outpath)');

    case '5'
      % Chen marginal
      log=evalc('dbExecuteMargLi(run_id,''chen'');');
    case '6'
      % Chib marginal
      log=evalc('dbExecuteMargLi(run_id,''chib'');');
  end

  % Store log.
  dbWriteLog(task_id,log);
  if verbose
    disp(log);
  end

  % Mark as finished.
  dbUpdateTaskStatus(task_id,'F');

catch err
  dbUpdateTaskStatus(task_id,'E');
  dbWriteLog(task_id,getReport(err));
  if verbose
    disp(getReport(err));
  end
end
