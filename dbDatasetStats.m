function dbDatasetStats(run_id)
% DBDATASETSTATS print basic descriptive statistics on run.

[trajData,exptDat,runDir,modelName] = dbGetData(run_id);

dsetfile = fullfile(runDir,['dsetExpt_' modelName '.mat']);
load(dsetfile);

fprintf('Averages across cells:-\n');
switch modelName
  case {'polewardhMC_SisterSwitcherproj','poleMShMCproj', ...
        'poleMShMC_SistersProj','polewardhMC_SisterSwitcherprojvplus0', ...
        'poleMShMCprojvplus0','poleMShMC_SistersProjvplus0'}
    vars = {'L','LogLi','ProbNoChgCoh','ProbNoChgInco','alpha','kappa','tau', ...
            'vminus','vplus'};
  case {'1D_harmonicwellMCMC','nocadozoletreated','MCMC1dHW'}
    vars = {'L','LogLi','kappa','tau'};
  case {'BM1D'}
    vars = {'L','LogLi','kappa','tau','v'};
end
maxLen = max(cellfun(@(x) length(x),vars));
fmt = sprintf('%%%ds %%10s %%10s\n',maxLen);
fprintf(fmt,'Variable','Mean','Std');
fmt = sprintf('%%%ds %% 4.4f %% 4.4f\n',maxLen);
for i=1:length(vars)
  mu = mean(dsetExpt.(vars{i}));
  sigma = std(dsetExpt.(vars{i}));
  fprintf(fmt,vars{i},mu,sigma);
end

