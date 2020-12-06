function dbReRun(runId,maxIters)
% DBRERUN increase maximum number of run iterations
%
%  dbReRun(runId,maxIters)
%

% Check existing max and convRc.
conn = dbOpen();
sql = sprintf('SELECT maxruns,conv_Rc FROM run WHERE id=%d;',runId);
results = table2cell(fetch(conn.conn, sql));
if isempty(results)
  error('No run with id %d found',runId);
end
curMaxIters = results{1,1};
convRc = results{1,2};
if ~isfinite(convRc)
  convRc = 1.2;
  disp('Using default Rc = 1.2');
end

if maxIters<=curMaxIters
  error('New max (%d) should be higher than old max (%d)',maxIters, ...
        curMaxIters);
end

% Update run.
sql = sprintf('UPDATE run SET maxruns=%d WHERE id=%d;',maxIters,runId);
dbCheck(exec(conn.conn, sql));

% Set tasks pending if not converged.
sql = sprintf(['UPDATE task SET status=''P'',pbsid=NULL WHERE run_id=%d AND type=1 '...
               'AND convergence>%g;'],runId,convRc);
dbCheck(exec(conn.conn, sql));

fprintf('Unconverged tasks for run %d are now pending\n',runId);
