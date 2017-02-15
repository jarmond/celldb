function dbExecuteSummary(trajData,model_name,exptData,outpath)

ReCompileMCMC_summaries(trajData,model_name,exptData,outpath,[],1);


% I Think this is all done in above... and ends up in dsetEventList...?

% nTraj = length(trajData(cellIdx).sisterList);
% for i = 1:nTraj
%   mcmcdat = dbGetRun(run_id,i,trajIdx,1);

%   EventList=generate_EventList(mcmcdat.mcmcparams,mcmcdat.mcmcrundirecs1,...
%                                mcmcdat.mcmcrundirecs2,[],[],[],[],1,1);
%   frces=computeForcesPosterior(mcmcdat.mcmcparams,mcmcdat.mcmcrun,mcmcdat.mcmcrundirecs1,...
%                                mcmcdat.mcmcrundirecs2,[],1,1)

%   dt=2;
%   EventList=add_forcesEventList(EventList,dt,[],frces);

%   SAVDIR=[mcmcparams.savedir '/' mcmcparams.filename 'Figs'];
%   save([SAVDIR '/events.mat'],'EventList');
% end