function dbImportKitData(directory,varargin)
% DBIMPORTKITDATA Import output files from KiT and produce trajData.mat
%
% Parameters required:-
%     directory: Location to search.
%
% Parameters optional:-
%     user: Initials or ID of experimenter. (default from login)
%     date: Date of experiment.
%     name: Short name for dataset, e.g. HeLaJ WT
%     description: Description of dataset.
%     cellline: Description of cellline.
%     microscope: Microscope used.
%     channel: Tracked channel to import. (default 1)
%     filter: Percentage contiguous track to require. (default 75)
%     mintraj: Minimum number of passing trajectories per cell (default 1)
%     overwrite: boolean, overwrite existing dataset
%     ignoreplane: Set to 1 to ignore requirement for plane fit.
%     ignoreanaphase: Set to 1 to ignore anaphase check.
%     maxdisp: Maximum frame-frame displacement to filter tracking errors. (default 1um).
%
% Missing optional parameters without defaults will be queried. Saves output in
% data folder.

if nargin<1
  directory = uigetdir('','Select folder to search for data');
end

if isempty(directory)
  error('Must supply directory');
end

% Make absolute path, if relative.
if directory(1) ~= filesep
  directory = fullfile(pwd,directory);
end

params.user = [];
params.date = [];
params.description = [];
params.cellline = [];
params.name = [];
params.channel = 1;
params.microscope = [];
params.filter = 75;
params.mintraj = 1;
params.overwrite = 0;
params.ignoreplane = 0;
params.ignoreanaphase = 0;
params.maxdisp = 1;
params = processOptions(params,varargin{:});

% Query missing parameters.
if isempty(params.user)
  % Guess user from login.
  params.user = dbGuessUser();
  if isempty(params.user)
    % Still don't know.
    dbShowUsers();
    params.user = input('Enter your user id or initials:');
  end
end
% Convert user to id.
if ~isscalar(params.user)
  params.user = dbGetId('user','initials',params.user);
  if params.user == 0
    error(['Unknown user:' params.user]);
  end
end
if isempty(params.date)
  params.date = input('Enter experiment date: ','s');
end
if isempty(params.name)
  params.name = input('Enter short name for experiment: ','s');
end
if isempty(params.description)
  params.description = input('Enter experiment description: ','s');
end
if isempty(params.cellline)
  params.cellline = input('Enter cell line code or ID: ','s');
end
if isempty(params.microscope)
  dbShowMicroscopes();
  params.microscope = input('Select microscope: ');
  if isempty(params.microscope)
    error('Must select microscope');
  end
end


% Replace spaces with _ in name.
params.name = canonicalName(params.name);

% Search for KiT files.
kitFiles = cuplFindFilesWithPrefix(directory,'kittracking');
if isempty(kitFiles)
  error('No files found in: %s',directory);
end

% Collect trajectories.
kk = 0;
t = 1;
cull = [];
for i=1:length(kitFiles)
  f = kitFiles{i};
  fprintf('Importing %s\n',f);
  job = load(f);
  if ~isfield(job,'dataStruct')
    disp('Data missing');
    continue;
  end
  ds = job.dataStruct{params.channel};
  if ~isfield(ds,'sisterList')
    disp('sisterList missing');
    continue
  end
  if ~params.ignoreplane && (~isfield(ds,'planeFit') || isempty(ds.planeFit) || any(cellfun(@isempty,{ds.planeFit.plane})))
    disp('Some frames missing plane fit');
    continue
  end

  % Form MCMC-compatiable trajData structure.
  trajData(t).cellIdx = i;
  [path,name,ext] = fileparts(f);
  trajData(t).cellName = [name ext];
  trajData(t).cellPath = path;
  trajData(t).movieFile = job.movie;

  k=0;
  n=length(ds.sisterList);
  for j=1:n
    if isempty(ds.sisterList(j).coords1)
      fprintf('Empty sisterlist, skipping\n');
      continue
    end

    % Check for anaphase onset.
    phase = vertcat(ds.planeFit.phase);
    anaOnset = find(phase=='a',1);
    if ~params.ignoreanaphase &&  ~isempty(anaOnset)
      fprintf('Anaphase detected in cell %d trajectory %d, restricting trajectory to metaphase.\n',i,j);
      c1 = ds.sisterList(j).coords1(1:anaOnset-1,1:3);
      c2 = ds.sisterList(j).coords2(1:anaOnset-1,1:3);
    else
      c1 = ds.sisterList(j).coords1(:,1:3);
      c2 = ds.sisterList(j).coords2(:,1:3);
    end

    % Filter NaNs.
    x = c1(:,1);
    f = find([1; isnan(x); 1]); % NaN indices.
    z = diff(f)-1; % Lengths of contiguous non-nan segments.
    [mz,mi] = max(z);
    if mz < length(x)*params.filter/100;
      continue
    end
    % Restrict trajectory to longest non-nan segment.
    rng = f(mi):f(mi+1)-2;
    c1 = c1(rng,:);
    c2 = c2(rng,:);

    % Filter tracking errors.
    dc1 = abs(diff(c1));
    dc2 = abs(diff(c2));
    if any(dc1(:)>params.maxdisp) || any(dc2(:)>params.maxdisp)
      fprintf('Tracking error in cell %d trajectory %d.\n',i,j);
      continue
    end

    % Trajectory passed.
    k=k+1;
    ds.sisterList(j).idx = j;
    ds.sisterList(j).coords1 = c1;
    ds.sisterList(j).coords2 = c2;
    % Nigel's code expects a row vector of sisterLists.
    trajData(t).sisterList(1,k) = ds.sisterList(j);
  end
  fprintf('%d trajectories out of %d passed filtering\n',k,n);
  if k < params.mintraj
    % Filter out cells with less than minimum passing trajectories.
    cull(end+1) = t;
  end
  kk = kk + k;
  t = t+1;
end
trajData(cull) = [];

fprintf('Found %d sisters from %d cells (%d input)\n',kk,length(trajData),length(kitFiles));
username = dbShowUsers(params.user);

% Form ExptDat structure.
ExptDat.name = params.name;
ExptDat.dir = params.name;
ExptDat.sourceFile = directory; % Record searched directory here.
ExptDat.date = params.date;
% Read off deltaT from last file.
ExptDat.deltat = diff(job.metadata.frameTime(1,1:2));
ExptDat.cellLine = params.cellline;

% Extra information.
ExptDat.description = params.description;
ExptDat.channel = params.channel;
ExptDat.wavelength = job.metadata.wavelength(params.channel);
ExptDat.user = username;

% Make directory and save data under user folder in DB data folder.
global dbdatapath;
if ~exist(fullfile(dbdatapath,username))
  % Create user folder.
  mkdir(dbdatapath,username);
end
outpath = fullfile(dbdatapath,username);
fprintf('Storing under %s...',outpath);
mkdir(outpath,params.name);
trajFile = fullfile(outpath,params.name,['trajData_' params.name '.mat']);
save(trajFile,'trajData');
exptFile = fullfile(outpath,params.name,'ExptDat.mat');
save(exptFile,'ExptDat');
fprintf('done\n');

% Add to database.
fprintf('Adding to database...');
id=dbAddExperiment(trajFile,params.name,'initials',username,'microscope', ...
                   params.microscope, 'date',params.date, 'cellLine', ...
                   params.cellline,'desc',params.description,'overwrite',params.overwrite);
fprintf('ID = %d, done\n',id);
