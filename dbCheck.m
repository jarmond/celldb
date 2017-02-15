function dbCheck(cursor)
% Check for a error message from db and throw if found. Closes cursor after checking.

if ~isempty(cursor.Message)
  st = dbstack(1);
  caller = st(1);
  e = MException(['ktdb:' caller.name ':dbError'],...
                 'DB error: %s',cursor.Message);
  throw(e);
end

% Close cursor to recover resources.
close(cursor);

