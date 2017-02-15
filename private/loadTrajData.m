function trajData = loadTrajData(file)
% Load trajData from file. Try various hacks if its not in a standard format.

d = load(file);
if isfield(d,'TrajDat')
  trajData = d.TrajDat;
elseif isfield(d,'trajDat')
  trajData = d.trajDat;
else
  % Some files annoyingly have different name structs inside.  Search fields for
  % trajdat prefix.
  f = fieldnames(d);
  m = strfind(cellfun(@(x) lower(x),f,'uniformoutput',false),'trajdat');
  % Take first match.
  for i=1:length(m)
    if ~isempty(m{i})
      trajData = d.(f{i});
      return;
    end
  end

  % Failed to find suitable field.
  error('Could not find TrajDat within %s',file);
end

