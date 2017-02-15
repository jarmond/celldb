function filenames=cuplFindFilesWithPrefix(directory,prefix)
%CUPLFINDFILESWITHPREFIX  Recursively search for maki files in a directory tree.
%
%   FILENAMES = CUPLFINDFILESWITHPREFIX(DIRECTORY) returns a cell array
%   containing the filenames of all files starting with PREFIX in the DIRECTORY
%   tree.
%
% Copyright (c) 2010 Elina Vladimirou
% Copyright (c) 2013 Jonathan Armond

filenames = {};
files = dir(directory);
for i=1:length(files)
    %if strncmp(files(i).name,prefix,length(prefix))
    if ~isempty(regexp(files(i).name, [prefix '.*mat'],'match'));
        % A file with the prefix.
        filenames = [filenames; [fullfile(directory,files(i).name)]];
    end
    
    % Search subdirectories.
    if files(i).isdir && files(i).name(1) ~= '.'
        filenames = [filenames; cuplFindFilesWithPrefix(fullfile(directory,files(i).name),prefix)];
    end
end
