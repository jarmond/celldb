function filename=makeFilename(type,runDir,modelName,exptName,cellIdx,trajIdx,chain)

type = lower(type);
%modelName = standardizeModelName(modelName);

if nargin>=5
  cellDir = [exptName '_Cell' num2str(cellIdx)];
end

switch type
  case 'summary'
    filename = fullfile(runDir,cellDir,['MCMCsummary_' modelName '.mat']);
  case 'dsetexpt'
    filename = fullfile(runDir,['dsetExpt_' modelName '.mat']);
  case 'convreport'
    filename = fullfile(runDir,['convergenceReport_' modelName '.mat']);
  case 'margli'
    filename = fullfile(runDir,['margli_' modelName '.mat']); % modelName is algorithm here.
  case 'traj'
    if nargin<6
      % Just return stub.
      filename = fullfile(runDir,cellDir,['MCMC_' modelName '_Traj']);
    else
      if nargin<7
        chain = 1;
      end
      filename = fullfile(runDir,cellDir,['MCMC_' modelName '_Traj' num2str(trajIdx) ...
                        'output' num2str(chain) '.mat']);
    end
  case 'convdiag'
    filename = [makeFilename('traj',runDir,modelName,exptName,cellIdx) num2str(trajIdx) ...
                'convergencediag.mat'];
  case 'trajfigs'
    filename = fullfile(runDir,cellDir,['MCMC_' modelName '_Traj' num2str(trajIdx) ...
                        'Figs']);
  otherwise
    error('Unknown filename type: %s',type);
end
