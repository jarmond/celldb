function initparams=dbGetDefaultInitParams(model_id)
% Retrieve default initial parameters for given model.

conn = dbOpen();

sql = sprintf('SELECT definitparams FROM model WHERE id=%d;',model_id);
results = fetch(conn.conn,sql);
row = results(1);
initparams = str2num(row{1});

