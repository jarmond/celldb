function exptpath=dbExptDataPath(file)

path = fileparts(file);
exptpath = fullfile(path,'ExptDat.mat');