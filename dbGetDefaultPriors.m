function priorStruct=dbGetDefaultPriors(model_id)
% Retrieve default priors for given model.

conn = dbOpen();

sql = sprintf('SELECT defaultpriors FROM model WHERE id=%d;',model_id);
results = table2cell(fetch(conn.conn,sql));
row = results(1);
priors = row{1};

% Parse assignments.
assigns = strsplit(priors,';');

% Build struct.
for i=1:length(assigns)
  if ~isempty(assigns{i})
    % Split assignment.
    s = strsplit(assigns{i},'=');
    priorStruct.(s{1})=eval(s{2});
  end
end
