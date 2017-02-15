function dbNocodazoleLPrior(runId,ev)

% TODO check convergence?

if nargin<2
  ev = 0.1; % Explaned variance threshold.
end

conn = dbOpen();
sql = sprintf(['SELECT model.name,run.name '...
       'FROM run '...
       'JOIN model ON model_id = model.id '...
       'WHERE run.id = %d'],runId);
results = fetch(conn.conn,sql);
if isempty(results)
  error('No such run id %d',runId);
end

global dbrunpath;
row = results(1,:);
modelName = row{1};
runName = row{2};
runDir = [dbrunpath filesep runName];

dsetFilename=makeFilename('dsetexpt',runDir,modelName);
load(dsetFilename,'dsetExpt');

figure(1);
histogram(dsetExpt.ExplnedVar);
xlabel('EV');

sel = dsetExpt.ExplnedVar > ev;

figure(2);
histogram(dsetExpt.L(sel));
xlabel('posterior mean L');

[m,sd,v,sem,n]=grpstats(dsetExpt.L(sel),[],{'mean','std','var','sem','numel'});
summary=sprintf('mean %.4f var %.4f std %.4f sem %.4f n %d of %d at EV>%g',m,v,sd,sem,n,numel(dsetExpt.ExplnedVar),ev);
disp(summary);
title(summary);

