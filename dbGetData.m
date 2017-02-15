function [trajData,ExptDat,runDir,modelName]=dbGetData(run_id)
% DBGETDATA retrieves data structures for run

conn = dbOpen();

sql = sprintf(['SELECT model.name,experiment.file,run.name '...
       'FROM run '...
       'JOIN model ON model_id = model.id '...
       'JOIN experiment ON experiment_id = experiment.id '...
       'WHERE run.id = %d'],run_id);
results = fetch(conn.conn,sql);
if isempty(results)
  error('No such run id %d',run_id);
end

row = results(1,:);
modelName = row{1};
trajPath = row{2};
runName = row{3};

global dbdatapath dbrunpath;
trajPath = fullfile(dbdatapath,trajPath);
exptPath = exptDataPath(trajPath);
runDir = [dbrunpath filesep runName];

trajData = struct2cell(load(trajPath));
trajData = trajData{1};
load(exptPath);
