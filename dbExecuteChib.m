function dbExecuteChib(trajData,model_name,rundata,exptData,outpath,run_id)
% DBCHIB executes reduced conditional MCMCs to evaluate Chib marg li.


if strcmp('poleMShMCproj',model_name)==0 && ...
      strcmp('poleMShMCprojvplus0',model_name)==0
  error('Model %s not supported for Chib at this time.',model_name);
end

% Make output directories.
params = {'tau','vplus','vminus','L','kappa','alpha'};
nParams = length(params);
outdirs = cellfun(@(x) fullfile(outpath,[x 'fix']),params,'uniformoutput',false);
cellfun(@(x) mkdir(x),outdirs);

% Run Chib with successive variables fixed.
modoptions=[];
modoptions.fulldir=outpath;
modoptions.compilecells=0;

% Record stages done, in case need to rerun since so time consuming.
note = exptData.name;
notefile = 'done.mat';

% Calculate fixed points.
nTraj = length(trajData.sisterList);
fixedpts = zeros(nTraj,nParams);
for j=1:nTraj
  fprintf('Fixed point trajectory %d:-\n',j);
  mcmcdat = dbGetRun(run_id,trajData.cellIdx,trajData.sisterList(j).idx,1);
  % MLE estimate for theta.
  burnin = mcmcdat.mcmcparams.burnin;
  logLi = mcmcdat.mcmcrun(burnin+1:end,9);
  [~,logLiMaxIdx] = max(logLi);
  fixedpts(j,:) = mcmcdat.mcmcrun(burnin+logLiMaxIdx,1:nParams);
  for i=1:nParams
    fprintf(' %s = %f\n',params{i},fixedpts(i));
  end
end
modoptions.fixedpts=fixedpts;

% Fix tau.
modoptions.taufix=1;
donefile = fullfile(outdirs{1},notefile);
if exist(donefile) ~= 2
  RunMCMC(trajData,model_name,rundata,exptData,outdirs{1},0,modoptions);
  save(donefile,'note');
else
  disp('tau already done, skipping');
end

if strcmp('poleMShMCprojvplus0',model_name)==0
  % Fix vplus.
  modoptions.vplusfix=1;
  donefile = fullfile(outdirs{2},notefile);
  if exist(donefile) ~= 2
    RunMCMC(trajData,model_name,rundata,exptData,outdirs{2},0,modoptions);
    save(donefile,'note');
  else
    disp('vplus already done, skipping');
  end
end

% Fix vminus.
modoptions.vminusfix=1;
donefile = fullfile(outdirs{3},notefile);
if exist(donefile) ~= 2
  RunMCMC(trajData,model_name,rundata,exptData,outdirs{3},0,modoptions);
  save(donefile,'note');
else
  disp('vminus already done, skipping');
end

% Fix L.
modoptions.Lfix=1;
donefile = fullfile(outdirs{4},notefile);
if exist(donefile) ~= 2
  RunMCMC(trajData,model_name,rundata,exptData,outdirs{4},0,modoptions);
  save(donefile,'note');
else
  disp('L already done, skipping');
end

% Fix kappa.
modoptions.kappafix=1;
donefile = fullfile(outdirs{5},notefile);
if exist(donefile) ~= 2
  RunMCMC(trajData,model_name,rundata,exptData,outdirs{5},0,modoptions);
  save(donefile,'note');
else
  disp('kappa already done, skipping');
end

% Fix alpha.
modoptions.alphafix=1;
donefile = fullfile(outdirs{6},notefile);
if exist(donefile) ~= 2
  RunMCMC(trajData,model_name,rundata,exptData,outdirs{6},0,modoptions);
  save(donefile,'note');
else
  disp('alpha already done, skipping');
end
