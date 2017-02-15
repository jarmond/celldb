function dbMakeFigures(run_id,varargin)
% DBMAKEFIGURES Generate standard figures for run.
%
% Accepts options as name/value pairs.
%
% 'exptOnly' : set to 1 to plot only figures for whole experiment
% 'cellsOnly' : set to 1 to plot only individual cell figures
% 'EVthreshold' : set EV threshold for filtering, default 0.25
% 'forceAll' : force replot, even if up-to-date figure already exists
%
% jwa 04/15

opts.exptOnly = 0; % Only plot whole experiment figures
opts.cellsOnly = 0; % Only plot individual cell figures
opts.EVthreshold = 0.25;
opts.forceAll = 0; % Force replot of all figures
opts = processOptions(opts,varargin{:});

if opts.exptOnly && opts.cellsOnly
  error('exptOnly and cellsOnly mutually exclusive');
end


[trajData,exptDat,runDir,modelName]=dbGetData(run_id);
altMod = altModelName(modelName);

if ~opts.cellsOnly
  dsetfile = fullfile(runDir,['dsetExpt_' modelName '.mat']);
  disp(['Loading ' dsetfile]);
  load(dsetfile);

  fprintf('Plotting whole experiment figures for run %d\n',run_id);
  %vars = {'L','LogLi','ProbNoChgCoh','ProbNoChgInco','alpha','kappa','tau', ...
  %        'vminus','vplus'};
  %view_stats(dsetExpt,vars,runDir);

  % Filter on Explained variance.
  if ~isempty(opts.EVthreshold)
    JEV=find(dsetExpt.ExplnedVar>opts.EVthreshold);
  else
    JEV=1:length(dsetExpt);
  end
  JEVcodes=unique(dsetExpt.Code(JEV));
  %J=ismember(dsetEventList.Code,JEVcodes);

  compute_MCMCstats_pooled(pooledsamples,dsetExpt,JEV,exptDat,runDir, ...
                           modelName,runDir);

  if ~isempty(dsetEventList)
    ProfileCat=augment_ProfileCat(ProfileCat,dsetEventList,[],JEVcodes,'EV25', ...
                                  {'additive',0.33},[],1,runDir);
    ProfileCat=profileCat_add_combinedvar(ProfileCat);
    evcatLead=profCat_view_events(ProfileCat,'EndLead','All',0,[],runDir);
  else
    disp('No events. Skipping event plots.');
  end
end

close all;
if opts.exptOnly
  return
end

conn = dbOpen();
nCells = length(trajData);
for i=1:nCells
  fprintf('Plotting figures for cell %d\n',i);
  cellIdx = trajData(i).cellIdx;
  cellDir = fullfile(runDir,[exptDat.name '_Cell' num2str(cellIdx)]);

  nTraj = length(trajData(i).sisterList);
  for j=1:nTraj
    trajIdx = trajData(i).sisterList(j).idx;
    
    % Check if figures are missing or out of date before plotting
    % trajFile = makeFilename('traj',runDir,modelName,exptDat.name,cellIdx, ...
    %                         trajIdx,1);
    % trajMod = fileModtime(trajFile);
    % trajFigdir = makeFilename('trajfigs',runDir,modelName,exptDat.name, ...
    %                           cellIdx,trajIdx);
    
    
    mcmcdat = dbGetRun(run_id,cellIdx,trajIdx,1,conn);
    if ~isempty(mcmcdat)
      plot_mcmcRun_basicvariables(mcmcdat.mcmcparams,mcmcdat.mcmcrun,[]);
      if strcmp(modelName,'poleMShMCproj') || ...
          strcmp(modelName,'poleMShMCprojvplus0')
        plot_mcmcRun_hMCsisterSwt(mcmcdat.mcmcparams,mcmcdat.mcmcrun, ...
                                  mcmcdat.mcmcrundirecs1, ...
                                  mcmcdat.mcmcrundirecs2,[],[],1);
      end
      if ~opts.cellsOnly
        plot_direcs(mcmcdat,dsetEventList,[],[],mcmcdat.mcmcparams.savedir);
      end
    end
    close all;
  end
end

close all;

