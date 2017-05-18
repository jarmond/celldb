function GR=dbUpdateConvergence(taskId,runId,cellIdx,trajIdx)
% Update DB record of convergence statistic for task.


conn = dbOpen();
[~,ExptDat,runDir,modelName]=dbGetData(runId);

maxGR=-inf;
for i=1:length(trajIdx)
    diagfile = makeFilename('convdiag',runDir,modelName,ExptDat.name,cellIdx,trajIdx(i));

    % Extract worst case GR statistic.
    try
        d=load(diagfile);
        GR=max(d.mcmcdiagnos.GR.Rc);
        maxGR = max(maxGR,GR);
    catch
        % Presumably diag file missing.
    end
end

if isfinite(maxGR)
  sql = sprintf('UPDATE task SET convergence=%f WHERE id=%d;',maxGR,taskId);
  dbCheck(exec(conn.conn,sql));
end

