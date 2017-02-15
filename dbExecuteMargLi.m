function dbExecuteMargLi(run_id,alg)
% DBEXECUTEMARGLI executes marginal likelihood calculation on a run.
%
% Available algorithms: chen, chib, logli
%
% Chib requires reduced MCMCs to have been run. See DBMAKECHIBTASKS.
%

if nargin<2
  alg='chen';
end

% Get data for run.
[trajData,exptDat,runDir,modelName]=dbGetData(run_id);

% Find number of parameters for this model.
conn = dbOpen();
sql = sprintf(['SELECT numparams FROM model WHERE name=' interpString('s') ...
               ';'], modelName);
results = fetch(conn.conn,sql);
row = results(1,:);
nParams = row{1};

sql = sprintf('SELECT extra_options FROM run WHERE id=%d;',run_id);
results = fetch(conn.conn,sql);
row = results(1,:);
extraOpts = row{1};

if ~isempty(strfind(extraOpts,'projectionon=0'))
  projectionon = 0;
else
  projectionon = 1;
end

if ~isempty(strfind(extraOpts,'Lfix=1'))
  Lfix = 1;
else
  Lfix = 0;
end

nCells = length(trajData);
margLi = [];
for i=1:nCells
  cellIdx = trajData(i).cellIdx;
  nTraj = length(trajData(i).sisterList);

  for j=1:nTraj
    trajIdx = trajData(i).sisterList(j).idx;
    n = 2*(size(trajData(i).sisterList(j).coords1,1)-1); % displacements 2 KTs
    fprintf('Running %s marginal likelihood on run %d cell %d traj %d for model %s\n', ...
            alg, run_id, cellIdx, trajIdx, modelName);

    % Get run data.
    mcmcdat = dbGetRun(run_id,cellIdx,trajIdx,1);
    if isempty(mcmcdat)
      fprintf('Data missing...skipped\n');
      continue;
    end

    % Compute marginal likelihood.
    switch alg
      case 'chen'
        switch modelName
          case 'poleMShMCproj'
            [logLi,logMargLi,logMargLiVar] = computeMargLi(mcmcdat,'projection',projectionon,'Lfix',Lfix);
          case 'poleMShMCprojvplus0'
            [logLi,logMargLi,logMargLiVar] = computeMargLi(mcmcdat,'vpluszero',1,'projection',projectionon,'Lfix',Lfix);
          case 'BM1D'
            [logLi,logMargLi,logMargLiVar] = computeMargLiBM(mcmcdat);
          case 'BM1Dv0'
            [logLi,logMargLi,logMargLiVar] = computeMargLiBM(mcmcdat,'vzero',1);
          case 'BM1Dfree'
            [logLi,logMargLi,logMargLiVar] = computeMargLiBM(mcmcdat,'kappazero',1);
          otherwise
            error('Unsupported model: %s',modelName);
        end
      case 'logli'
        switch modelName
          case 'poleMShMCproj'
            logLi = computeMargLi(mcmcdat,'projection',projectionon,'Lfix',Lfix);
          case 'poleMShMCprojvplus0'
            logLi = computeMargLi(mcmcdat,'vpluszero',1,'projection',projectionon,'Lfix',Lfix);
          case 'BM1D'
            logLi = computeMargLiBM(mcmcdat);
          case 'BM1Dv0'
            logLi = computeMargLiBM(mcmcdat,'vzero',1);
          case 'BM1Dfree'
            logLi = computeMargLiBM(mcmcdat,'kappazero',1);
          otherwise
            error('Unsupported model: %s',modelName);
        end
        logMargLi = nan;
        logMargLiVar = nan;
      case 'chib'
        % Load reduced MCMCs.
        params = {'tau','vplus','vminus','L','kappa','alpha'};
        for p=1:length(params)
          reducedRun = dbGetRun(run_id,cellIdx,trajIdx,1,params{p});
          mcmcdat.(params{p}) = reducedRun;
        end
        switch modelName
          case 'poleMShMCproj'
            [logLi,logMargLi,logMargLiVar] = computeMargLiChib(mcmcdat);
          case 'poleMShMCprojvplus0'
            [logLi,logMargLi,logMargLiVar] = computeMargLiChib(mcmcdat,'vpluszero',1);
          otherwise
            error('Unsupported model: %s',modelName);
        end
    end

    % Compute AIC,BIC.
    aic = -2*logLi + 2*nParams;
    bic = -2*logLi + nParams*log(n);

    margLi = [margLi; cellIdx, trajIdx, makeCode(trajIdx,cellIdx), logMargLi, ...
              logMargLiVar, logLi, bic, aic];
  end
end

% Convert to table.
margLi = array2table(margLi,'VariableNames',{'CellIdx','TrajIdx','Code', ...
                    'LogMargLi','LogMargLiVar','LogLi','BIC','AIC'});

% Store result.
outname = makeFilename('margli',runDir,alg);
save(outname,'margLi');
