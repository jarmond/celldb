function priors=dbGetPriors(run_id)

conn = dbOpen();

sql = sprintf('SELECT priors FROM run WHERE id=%d;',run_id);
results = table2cell(fetch(conn.conn,sql));
row = results(1);
priorStr = row{1};

% Parse assignments.
assigns = strsplit(priorStr,';');

% Build struct.
priors.format='Structured';
for i=1:length(assigns)
  if ~isempty(assigns{i})
    % Split assignment.
    s = strsplit(assigns{i},'=');
    priors.variable{i}=s{1};
    priors.params{i}=eval(s{2});
  end
end
