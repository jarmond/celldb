function dbInit(db,usemex)
% Initialize db.

fprintf('Initializing Cell Database...\n');

if ~exist('./db.marker','file')
  error('Must be in CellDB directory to use database');
end

global dbsystem dbdatapath dbrunpath dbusemex;

dbcodepath=fullfile(pwd,'../code');
dbdatapath=fullfile(pwd,'../data');
dbrunpath=fullfile(pwd,'../MCMCruns');

codesubs = {};
addpath(dbcodepath);
for i=1:length(mcmcsubs)
  addpath(fullfile(dbcodepath, codesubs{i}));
end

if nargin>0
  dbsystem=db; % 'sqlite' or 'mysql'
else
  dbsystem='mysql';
end
if nargin>1
  dbusemex=usemex;
else
  dbusemex=1; % Default to C MEX version.
end

% Persist global vars to file, since javaaddpath clears workspace.
tmpfile = [tempname '.mat'];
save(tmpfile,'dbsystem','dbdatapath','dbrunpath','dbusemex');

switch dbsystem
  case 'sqlite'
    javaaddpath([pwd '/sqlite-jdbc-3.7.2.jar']);
  case 'mysql'
    javaaddpath([pwd '/mysql-connector-java-5.1.36-bin.jar']);
end

load(tmpfile);
delete(tmpfile);
fprintf('Using DB backend: %s\n',dbsystem);
fprintf('Ready.\n');
