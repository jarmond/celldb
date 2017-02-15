function dbLock(runId,action)
% DBLOCK Change permissions of run data
%
% runId : run ID of run to lock/unlock
% lockorunlock : 0 to lock, 1 to unlock
%
% jwa 04/15

% NB This is a not secure locking mechanism, since anybody can run a
% modification of this code and put whatever user they want. Thus the lock is
% just intended to avoid "accidents".
user = dbGuessUser();
userId = dbGetId('user','initials',user);

conn = dbOpen();

sql = sprintf('SELECT name FROM run WHERE id=%d AND user_id=%d;',runId,userId);
results = fetch(conn.conn,sql);
if isempty(results)
  error('You don''t own run %d or it doesn''t exist',runId);
end

global dbrunpath;
runDir = fullfile(dbrunpath,results{1,1});

switch action
  case 'lock'
    modStr = 'go-wX';
    fprintf('Locking:');
  case 'unlock'
    modStr = 'go+rwX';
    fprintf('Unlocking:');
  otherwise
    error('2nd parameter should be 0 to lock or 1 to unlock');
end
fprintf([' ' runDir '\n']);

% Change permissions.
[status,result] = system(['chmod ' modStr ' ' runDir]);
if status~=0
  fprintf('chmod failed: %s\n',result);
end

