function dbDeleteExperiment(expId,dryrun)
% Deletes experimental data from DB.
%
%  DBDELETEEXPERIMENT(EXPERIMENT_ID) to delete experiment
%    or
%  DBDELETEEXPERIMENT(EXPERIMENT_ID,1) to show SQL statements as dry experiment.

if nargin<2
  dryrun=0;
end


% Check experiment exists and is owned by user.
user = dbGuessUser();

conn = dbOpen();

sql = sprintf(['SELECT experiment.name,file FROM experiment JOIN user ON user_id=user.id '...
               'WHERE initials=' interpString('s') ' AND experiment.id=%d;'],user, ...
              expId);
results = fetch(conn.conn,sql);
if isempty(results)
  error('You have no experiment with id %d',expId);
end
row = results(1,:);
name = row{1};
trajPath = row{2};

% Check if runs exist using this data.
sql = sprintf('SELECT run.id FROM run WHERE experiment_id=%d;',expId);
results = fetch(conn.conn,sql);
if ~isempty(results)
  disp(['Runs exist using this experiment: ' num2str(cell2mat(results(:)))]);
  disp('Delete these runs first.');
  return
end


% Delete the experiment.
reply = input(['Really delete experiment ' name '? (y/n): '],'s');
if isempty(reply) || reply(1) ~= 'y'
  disp('Aborted.');
  return
end

% Delete data.
global dbdatapath;
trajPath = fullfile(dbdatapath,trajPath);
dataPath = fileparts(trajPath);
cmd = sprintf('rm -rf %s',dataPath);
if dryrun
  disp(cmd);
else
  system(cmd);
end

sql = sprintf('DELETE FROM experiment WHERE id = %d;',expId);
if dryrun
  disp(sql);
else
  dbCheck(exec(conn.conn,sql));
end

