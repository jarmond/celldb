function dbFindExperiments(directory,initials)

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

if nargin<2
  dbShowUsers();
  initials = input('Enter experimenter initials to record data under: ','s');
end

dbShowMicroscopes();
microscope = input('Select microscope: ');

fprintf('Searching %s:\n',directory);

% Search for trajData.mat files.
expFiles = cuplFindFilesWithPrefix(directory,'trajData');
for i=1:length(expFiles)
  trajFile = expFiles{i};
  exptFile = exptDataPath(trajFile);
  load(exptFile);

  fprintf('Adding %s\n',ExptDat.name);
  dbAddExperiment(initials,microscope,trajFile,ExptDat.date, ...
                  ExptDat.cellLine,ExptDat.name,'');
end
