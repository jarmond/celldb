function str=sqlEscape(str,illegals)
% Escapes a string for use in SQL query

if nargin<2
  illegals='\''"'; % default for SQL.
end

for i=1:length(illegals)
  c = illegals(i);
  str = strrep(str,c,['\' c]);
end
