function dbMakeChibTasks(run_id,subset)
% DBMAKECHIBTASKS runs the Chib reduced MCMCs
%
% subset is cellIdx's

conn = dbOpen();

% Get data for run.
[trajData,exptDat,runDir,modelName]=dbGetData(run_id);

nCells = length(trajData);
if nargin<2
  subset = vertcat(trajData.cellIdx);
else
  % Convert to trajData idx's
  [li,loc] = ismember(subset,vertcat(trajData.cellIdx));
  subset = loc(li);
end

for i=subset
  cellIdx = trajData(i).cellIdx;

  fprintf('Creating Chib task for run %d cell %d\n', ...
          run_id, cellIdx);
  sql = sprintf(['INSERT INTO task (run_id,trajdata_idx,status,type) VALUES ('...
                 interpString('ddsd') ');'],run_id,i,'P',3);
  dbCheck(exec(conn.conn, sql));
end

