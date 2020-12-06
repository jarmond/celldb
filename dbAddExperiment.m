function id=dbAddExperiment(file,name,varargin)
% DBADDEXPERIMENT Add experiment to db.
%
% Required arguments:
% file : Path to trajectory data file, either relative to dbdatapath or
% absolute (if absolute, should still be within DB data directory). Should
% contain a struct named TrajDat with fields
%   .cellIdx : cell number referring to original microscopy file.
%   .sisterList : trajectory data of KT sisters
%
% name : string, unique name for the experiment to use in the DB.
%
%
% Accepts options with name/value pairs:
% 'initials' : user initials to associate with data. Default inferred from login
% 'microscope' : name or id of microscope. Default: ultraview
% 'date' : string representation of experiment date
% 'cellLine' : code (e.g. MC24) or id describing cellLine.
% 'desc': string, free-form description of experiment
% 'overwrite': boolean, overwrite existing dataset

opts.initials = dbGuessUser();
opts.microscope = 1;
opts.date = datestr(now);
opts.cellLine = [];
opts.desc = '';
opts.overwrite = 0;
opts = processOptions(opts,varargin{:});

% If absolute path, remove DB data prefix to make relative.
global dbdatapath;
if file(1) == filesep
  if isempty(strfind(file,dbdatapath))
    error('Data file must be within DB datapath (%s)',dbdatapath);
  end
  file = strrep(file,[dbdatapath filesep],'');
end

conn = dbOpen();

% Check experiment file not already added.
if ~opts.overwrite
  sql = sprintf('SELECT 1 FROM experiment WHERE file = ''%s'';',file);
  results = fetch(conn.conn, sql);
  if ~isempty(results)
    error('Experiment file already known, not adding: %s',file);
  end
end

% Lookup initials.
if ischar(opts.initials)
  userid = dbGetId('user','initials',opts.initials);
end

if ~dbValidId('user',userid)
  dbShowUsers();
  error('Unknown user %s',opts.initials);
end


% Verify microscope.
if ischar(opts.microscope)
  opts.microscope = dbGetId('microscope','name',opts.microscope);
end

if ~dbValidId('microscope',opts.microscope)
  dbShowMicroscopes();
  error('Unknown microscope %s',opts.microscope);
end

% Verify cell line.
if ischar(opts.cellLine)
  opts.cellLine = dbGetId('cellline','code',opts.cellLine);
end

if ~dbValidId('cellline',opts.cellLine)
  dbShowCellLines();
  error('Unknown cell line %s',opts.cellLine);
end

% Open file and find out how many cells are stored.
absfile = fullfile(dbdatapath,file);
% Check data file exists.
if ~exist(absfile,'file')
  error(['Data file not found:' absfile]);
end

trajData = loadTrajData(absfile);
if isempty(name)
  % Try to get a name from trajData or ExptDat nearby.
  if isfield(trajData,'name')
    name = trajData.name;
    fprintf('Found name in trajData: %s\n',name);
  else
    exptData = loadExptData(absfile);
    if isempty(exptData)
      error('Must supply name');
    else
      name = exptData.name;
      fprintf('Found name in ExptDat: %s\n',name);
    end
  end

  reply = input('Use it? Y/N [Y]:','s');
  if isempty(reply)
    reply = 'Y';
  end
  if upper(reply) == 'N'
    fprintf('Aborted.\n');
    return;
  end
end

numCells = length(trajData);

% Do some data integrity checks.
reqFields = {'sisterList','cellIdx'};
for i=1:length(reqFields)
  if ~isfield(trajData,reqFields{i})
    error('trajData missing required field .%s',reqFields{i});
  end
end
if ~isfield(trajData(1).sisterList,'idx')
  error('sisterList missing required field .idx');
end

if length(unique(vertcat(trajData.cellIdx))) ~= numCells
  error('trajData.cellIdx is not unique');
end


% Store in DB.
if opts.overwrite
  mode = 'REPLACE';
else
  mode = 'INSERT';
end
clear trajData;

sql = [mode ' INTO experiment '...
       '(user_id,microscope_id,file,date,cellline_id,name,description,num_cells'];
if opts.overwrite
  % Find original id.
  id = dbGetId('experiment','file',file);
  if id==0
    error('Trying to overwrite experiment but cannot find existing.');
  end
  sql = [sql ',id'];
end
sql = [sql sprintf([') VALUES (' interpString('ddssdssd')],...
      userid,opts.microscope,file,opts.date,opts.cellLine,name,opts.desc,numCells)];
if opts.overwrite
  sql = [sql ',' num2str(id)];
end
sql = [sql ');'];
dbCheck(exec(conn.conn, sql));

sql = sprintf(['SELECT id FROM experiment WHERE file=' interpString('s') ';'],file);
results = table2cell(fetch(conn.conn, sql));
assert(~isempty(results));
id = results{1,1};
