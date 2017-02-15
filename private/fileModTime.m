function modTime = fileModTime(filename)
% Return last modified time of fiel.

d = dir(filename);
if numel(d) == 0
  error('File not found: %s', filename);
elseif numel(d) > 1
  error('File specifier not unique: %s', filename);
end

modTime = d.datenum;
