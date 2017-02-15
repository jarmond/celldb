function s=interpString(fmt)
% Produce a string from interpolating values in SQL.
% TODO use format string like dssds

s = {};
for i=1:length(fmt)
  f = fmt(i);
  switch f
    case 's'
      s = [s '''%s'''];
    case 'd'
      s = [s '%d'];
  end
end
s = strjoin(s,',');
