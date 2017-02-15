function name=canonicalName(name)
% Standardizes name by substituting illegal characters with _

illegals=' /&';
for i=1:length(illegals)
  c = illegals(i);
  name = strrep(name,c,'_');
end
