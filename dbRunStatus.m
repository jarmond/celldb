function dbRunStatus(runId)
% DBRUNSTATUS Queries completion of various stages of run analysis.

% TODO distinguish between pending MCMC and summary/margli tasks

conn = dbOpen();

sql = sprintf(['SELECT status,count(*) FROM task WHERE run_id=%d GROUP BY ' ...
               'status;'],runId);
results = fetch(conn.conn,sql);
if isempty(results)
  error('No such run id %d or no tasks',run_id);
end

nPending = 0;
haserror = 0;
status = [];
nRows = size(results,1);
for i=1:nRows
  count = results{i,2};
  switch results{i,1}
    case 'E'
      haserror = 1;
    case 'R'
      status = [num2str(count) ' running'];
      break;
    case 'P'
      nPending = count;
  end
end

isFinished = 0;
if isempty(status)
  if nPending == 0
    status = 'finished';
    isFinished = 1;
  else
    status = 'pending';
  end
end

if haserror
  status = [status ', with errors'];
end

fprintf('MCMC: %s\n',status);

if isFinished
  missing = false(1,4); % summaries, dset, conv, chen
  fileDesc = {'Summary','Dataset summary','Convergence report','Marginal likelihood'};
  missingFile = cell(4,1);

  sql = sprintf(['SELECT finish,numchains FROM task JOIN run ON '...
                 'task.run_id=run.id WHERE run_id=%d AND type<=2 ORDER BY finish ' ...
                 'DESC LIMIT 1;'],runId);
  results = fetch(conn.conn,sql);
  finish = datenum(results{1,1});
  numchains = results{1,2};

  % Check summaries.
  [trajData,ExptDat,runDir,modelName]=dbGetData(runId);
  for i=1:length(trajData)
    filename = makeFilename('summary',runDir,modelName,ExptDat.name, ...
                            trajData(i).cellIdx);
    % Check modification times of output in cell.
    for j=1:length(trajData(i).sisterList)
      for k=1:numchains
        trajfile = makeFilename('traj',runDir,modelName,ExptDat.name,...
                                trajData(i).cellIdx,trajData(i).sisterList(j).idx);
        if ~exist(filename,'file') || (exist(trajfile,'file') && ...
                                       fileModTime(filename) < fileModTime(trajfile))
          missing(1) = true;
          missingFile{1} = filename;
          break;
        end
      end
    end
  end

  % Check dset.
  filename = makeFilename('dsetexpt',runDir,modelName);
  if exist(filename,'file') == 0 || fileModTime(filename) < finish
    missing(2) = true;
    missingFile{2} = filename;
  end

  % Check convergence.
  filename = makeFilename('convreport',runDir,modelName);
  if exist(filename,'file') == 0 || fileModTime(filename) < finish
    missing(3) = true;
    missingFile{3} = filename;
  end

  % Check Chen marginal.
  filename = makeFilename('margli',runDir,'chen');
  if exist(filename,'file') == 0 || fileModTime(filename) < finish
    missing(4) = true;
    missingFile{4} = filename;
  end

  for i=1:length(missing)
    if missing(i)
      fprintf('%s file is missing or out-of-date: %s\n',fileDesc{i},missingFile{i});
    else
      fprintf('%s file is up-to-date\n',fileDesc{i});
    end
  end

end
