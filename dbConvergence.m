function convReport=dbConvergence(run_id,varargin)
% DBCONVERGENCE Determine convergence statistics on run.

opts.threshold=1.2;
opts.subset=[];
opts=processOptions(opts,varargin{:});

[trajData,exptData,runDir,modelName]=dbGetData(run_id);
% Convert model name to be compatible. OBSOLETE
% modelName=altModelName(modelName);

nCells = length(trajData);
if isempty(opts.subset)
  opts.subset = 1:nCells;
end

convReport = [];
for i=opts.subset
  cellData = trajData(i);
  cellIdx = cellData.cellIdx;

  % For each trajectory, try to load convergence diagnostics.
  for j=1:length(cellData.sisterList)
    trajNum = cellData.sisterList(j).idx;
    diagFile = fullfile(runDir,...
                        sprintf([exptData.name '_Cell%d'],cellIdx),...
                        sprintf(['MCMC_' modelName ...
                        '_Traj%dconvergencediag.mat'],trajNum));
    if exist(diagFile,'file')==0
      warning('Convergence diagnostics missing, cell %d traj %d',cellIdx, ...
              trajNum);
      fprintf('Expected file: %s\n',diagFile);
    else
      diags = load(diagFile);

      % Count failed trajectories.
      failed = max(diags.mcmcdiagnos.GR.Rc)>opts.threshold;
      convReport = [convReport; cellIdx, trajNum, makeCode(trajNum,cellIdx), ...
                    failed, diags.mcmcdiagnos.GR.Rc];
    end
  end

end

% Report failure rate.
failRate = sum(convReport(:,4))/size(convReport,1);
fprintf('Failure rate: %.2f%%\n',failRate*100);

% Save convergence data.
varNamesRc = cellfun(@(x) ['Rc_' x],diags.mcmcdiagnos.GR.varnames,'uniformoutput',0);
convReport = array2table(convReport,'VariableNames',{'CellIdx','TrajIdx', ...
                    'Code','IsFailed',varNamesRc{:}});
convReport.IsFailed = logical(convReport.IsFailed);
outname = makeFilename('convreport',runDir,modelName);
save(outname,'convReport');
fprintf('Saved: %s\n',outname);
