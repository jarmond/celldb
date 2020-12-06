function dbMakeTask(conn,run_id,experiment_id,subset,singletrajtasks)
% Add task to queue.

trajData = dbGetData(run_id);

if isempty(subset)
  sql = sprintf('SELECT num_cells FROM experiment WHERE id = %d;',experiment_id);
  results = table2cell(fetch(conn,sql));
  numCells = results{1};
  range = 1:numCells;
else
  range = subset;
end

for i=range
  if singletrajtasks
    for j=1:length(trajData(i).sisterList)
      sql = sprintf(['INSERT INTO task (run_id,trajdata_idx,status,cell_idx,'...
                     'sisterlist_idx) VALUES '...
                     '(%d,%d,''P'',%d,%d);'],run_id,i,trajData(i).cellIdx,...
                    j);
      dbCheck(exec(conn,sql));
    end
  else
    sql = sprintf(['INSERT INTO task (run_id,trajdata_idx,status,cell_idx,'...
                   'sisterlist_idx) VALUES '...
                   '(%d,%d,''P'',%d,%d);'],run_id,i,trajData(i).cellIdx,0);
    dbCheck(exec(conn,sql));
  end
end
