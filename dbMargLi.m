function dbMargLi(run_id,alg,subset)
% DBMARGLI makes task to run marginal likelihood
%
% alg: 'chen', 'chib' or 'logli', default 'chen'.

if nargin<2
  alg = 'chen';
end

switch alg
  case 'chen'
    alg = 5;
  case 'chib';
    alg = 6;
  case 'logli';
    alg = 7;
  otherwise
    error('Unknown algorithm: %s',alg);
end

conn = dbOpen();

% Get data for run.
fprintf('Creating marginal likelihood task for run %d\n',run_id);
sql = sprintf(['INSERT INTO task (run_id,status,type) VALUES ('...
               interpString('dsd') ');'],run_id,'P',alg);
dbCheck(exec(conn.conn, sql));


