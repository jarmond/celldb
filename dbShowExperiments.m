function dbShowExperiments(varargin)
% DBSHOWEXPERIMENTS Print list of experiments
%
% Optional parameters with name/value pairs:
%  'user' : user initial. Default you.
%  'id' : show detailed view of single experiment

opts.user=[];
opts.id=[];
if nargin>0
  opts = processOptions(opts,varargin{:});
end

conn = dbOpen();

% If ID specified
if ~isempty(opts.id)
  params = { 'experiment.id','@Experiment ID';
             'experiment.name','Experiment name';
             'experiment.description','Experiment description';
             'experiment.date','Experiment date';
             'microscope.name','Microscope';
             'cellline.name','Cell line';
             'cellline.description','Cell line description';
             'cellline.code','Cell line code';
             'num_cells','@Number of cells';
             'file','Data file';};
  sql = sprintf(['SELECT ' strjoin(params(:,1)',',') ...
                 ' FROM experiment JOIN microscope ON microscope_id=microscope.id ' ...
                 'JOIN cellline ON cellline_id=cellline.id WHERE experiment.id = %d;'], ...
                opts.id);
  results = fetch(conn.conn, sql);
  if isempty(results)
    fprintf('No experiment with ID %d\n',opts.id);
  else
    printHeader(sprintf('Info for experiment %d',opts.id));
    for i=1:size(params,1)
      desc = params{i,2};
      if desc(1) == '@'
        fprintf('%s: %d\n',desc(2:end),results{1,i});
      elseif desc(1) == '#'
        fprintf('%s: %f\n',desc(2:end),results{1,i});
      else
        fprintf('%s: %s\n',desc,results{1,i});
      end
    end
  end
  % Additional info.
  global dbdatapath
  fprintf('Data file path: %s\n',fullfile(dbdatapath,results{1,9}));
  return
end

sql = ['SELECT experiment.id,experiment.name,date,initials,file '...
       'FROM experiment LEFT JOIN '...
       'user ON user_id = user.id '];
if ~isempty(opts.user)
  if ischar(opts.user)
    sql = sprintf([sql 'WHERE initials = ' interpString('s')],opts.user);
  else
    sql = sprintf([sql 'WHERE user.id = %d'],opts.user);
  end
end
sql = [sql ' ORDER BY experiment.id;'];
results = fetch(conn.conn, sql);

global dbdatapath;

if isempty(results)
  fprintf('No experiments\n');
else
  printHeader('Experiments');
  %fileCol = 2;
  for i = 1:size(results,1)
    % Remove data path prefix for brevity.
    %results{i,fileCol} = strrep(results{i,fileCol},[dbdatapath filesep],'');
    fprintf('%d: %s - %s [%s] : %s\n',results{i,:});
  end
end
