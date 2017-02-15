function mcmcdat = dbGetRun(runId,cellIdx,trajNum,chain,fix,conn)
% DBGETRUN Retreive MCMC results (mcmcdat) for a run.
%
%  mcmcdat = dbGetRun(runId,cellIdx,trajNum,chain,fix)
%
% Parameters:-
%
%  runId : MCMC run ID, identified from dbShowRuns.
%  cellIdx : Cell number, identified from dbShowTasks.
%  trajNum : (optional) Trajectory number or list thereof, identified from trajData (obtainable from
%  dbGetData), default load all trajectories.
%  chain : (optional) MCMC chain number or list thereof, defaults to all.
%  fix : (optional string prefix) load a chain with a fixed parameter (for Chib marginal).

if nargin<3
  trajNum = [];
end
if nargin<4
  chain = [];
end
if nargin<5
  fix = [];
end
if nargin<6 || isempty(conn)
  conn = dbOpen();
end

sql = sprintf(['SELECT model.name,run.name,file,numchains '...
       'FROM run '...
       'JOIN model ON model_id = model.id '...
       'JOIN experiment ON experiment_id=experiment.id '...
       'WHERE run.id = %d'],runId);
results = fetch(conn.conn,sql);
if isempty(results)
  error('No such run id %d',runId);
end

row = results(1,:);
modelName = row{1};
runName = row{2};
file = row{3};
numchains = row{4};

global dbrunpath dbdatapath;
absfile = fullfile(dbdatapath,file);
exptData = struct2cell(load(exptDataPath(absfile)));
exptData = exptData{1};

outpath = fullfile(dbrunpath,runName);
if ~isempty(fix)
  outpath = fullfile(outpath,[fix 'fix']);
end
cellPath = fullfile(outpath,[exptData.name '_Cell' num2str(cellIdx)]);

if isempty(trajNum)
  trajData = dbGetData(runId);
  trajDataIdx = find(vertcat(trajData.cellIdx)==cellIdx);
  trajNum = vertcat(trajData(trajDataIdx).sisterList.idx);
end

if isempty(chain)
  chain = 1:numchains;
end

for i=1:length(trajNum)
  trajPath = fullfile(cellPath,['MCMC_' modelName '_Traj' num2str(trajNum(i)) 'output']);
  for j=1:length(chain)
    trajFile = [trajPath num2str(chain(j)) '.mat'];
    if exist(trajFile,'file')~=0
      fprintf('Loading trajectory %d chain %d\n',trajNum(i),chain(j));
      mcmcdat(i,j) = load(trajFile);
    else
      error('Trajectory file missing: %s',trajFile);
    end
  end
end

% Add indices.
for i=1:size(trajNum,1)
  for j=1:size(mcmcdat,2)
    mcmcdat(i,j).idx = trajNum(i);
    mcmcdat(i,j).chain = j;
  end
end

