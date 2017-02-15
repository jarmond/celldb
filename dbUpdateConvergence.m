function GR=dbUpdateConvergence(taskId,runId,cellIdx,trajIdx)
% Update DB record of convergence statistic for task.

% TODO support whole cell tasks?

conn = dbOpen();
[~,ExptDat,runDir,modelName]=dbGetData(runId);
diagfile = makeFilename('convdiag',runDir,modelName,ExptDat.name,cellIdx,trajIdx);

% Extract worst case GR statistic.
try
  d=load(diagfile);
  GR=max(d.mcmcdiagnos.GR.Rc);
catch
  % Presumably diag file missing.
  GR=nan;
end

if ~isnan(GR)
  sql = sprintf('UPDATE task SET convergence=%f WHERE id=%d;',GR,taskId);
  dbCheck(exec(conn.conn,sql));
end

