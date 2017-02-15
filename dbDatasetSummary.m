function [dsetExpt,dsetEventList]=dbDatasetSummary(run_id,subset)
% DBDATASETSUMMARY combines summaries of each cell into one large summary for
% dataset.

if isscalar(run_id)
  [trajData,exptDat,runDir,modelName] = dbGetData(run_id);
  if nargin>=2
    idx = vertcat(trajData.cellIdx)
    trajData = trajData(ismember(idx,subset));
  end
else
  if nargin>=2
    error('Cannot subset multiple runs');
  end

  trajData = [];
  for i=1:length(run_id)
    [trajDatai,exptDat,runDir,modelName] = dbGetData(run_id);
    trajDatai.runDir = runDir;
    trajDatai.exptDat = exptDat;
    trajData = [trajData; trajDatai];
  end
end
modelName = standardizeModelName(modelName);

[dsetExpt,dsetEventList] = generate_datasetMCMCruns(trajData,exptDat,runDir, ...
                                                  modelName);


% Combine ProfileCat, pooledsamples, and dseteventspool
subsample = 1;
pooledsamples=dataset();
dseteventspool=dataset();
celltraj=[];
ProfileCat=[];
switch modelName
  case {'poleMShMCproj','poleMShMCprojvplus0'}
    params = {'tau','vplus','vminus','L','kappa','alpha','ProbNoCh-coh','ProbNoCh-inco'};
  case 'MCMC1DHW'
    params = {'kappa','L','tau'};
  case {'BM1D','BM1Dv0','BM1Dfree'}
    params = {'kappa','L','tau','v'};
end

disp('Pooling samples:-');
for i=1:length(trajData)
  cellDir = fullfile(runDir,[exptDat.name '_Cell' ...
                      num2str(trajData(i).cellIdx)]);
  sumfile = ['MCMCsummary_' modelName '.mat'];
  %if exist(fullfile(cellDir,sumfile),'file')==0
    % Try alternate model name.
    %  sumfile = ['MCMCsummary_' altModelName(modelName) '.mat'];
    %end
  fprintf('Pooling: %s\n',fullfile(cellDir,sumfile));
  load(fullfile(cellDir,sumfile));

  pooled = mcmcCell.mcmcsamplespooled;
  if ~isempty(pooled) % does this include the burnin?
    pooledsamples=[pooledsamples; dataset({pooled(1:subsample:end,1)+ ...
                        trajData(i).cellIdx*1000,'Code'}, ...
                                          {trajData(i).cellIdx*ones(size(pooled(1:subsample:end,:),1),1),'Cell'},{pooled(1:subsample:end,:),'Traj',params{:},'LogLi'})];
  end

  % NB On reasonably sized datasets, this gets ridiculously huge.
  % dseteventspool_p = mcmcCell.eventpool;
  % if ~isempty(dseteventspool_p)
  %   dseteventspool=[dseteventspool; dseteventspool_p];
  % end

  if ~isempty(ProfileCat)
    celltraj=[celltraj ProfileCat.celltraj]; % Augment profiles
  end

end
ProfileCat.celltraj=celltraj; % Compile across cells

% TODO
% Run convergence test and join data into this.
% Convert to using table.

outfile = makeFilename('dsetexpt',runDir,modelName);
disp(['Saving ' outfile]);
save(outfile,'dsetExpt','dsetEventList','pooledsamples','ProfileCat','-v7.3');


