function dbCompileSummaries(run_id,subset)
% DBCOMPILESUMMARIES recompiles summaries on run data for each cell.

if nargin<2
  subset=[];
end

conn = dbOpen();

[trajData,exptDat,runDir,modelName] = dbGetData(run_id);
nCells = length(trajData);
if isempty(subset)
  subset = 1:nCells;
end

switch modelName
  case {'poleMShMCproj','poleMShMCprojvplus0'}
    % Generate tasks for batch processing.
    for i=subset
      fprintf('Creating compile summaries task for run %d cell %d\n', ...
              run_id, i);
      % Set sisterlist_idx to zero to run on whole cell.
      sql = sprintf(['INSERT INTO task (run_id,trajdata_idx,status,type,cell_idx,sisterlist_idx) VALUES ('...
                     interpString('ddsddd') ');'],run_id,i,'P',4,trajData(i).cellIdx,0);
      dbCheck(exec(conn.conn, sql));
    end

  otherwise
    % Run immediately.
    dbExecuteSummary(trajData(subset),modelName,exptDat,runDir);
end


