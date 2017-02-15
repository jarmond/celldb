function exptData = dbGetExptDat(trajfile,trajData)
% Loads ExptDat struct associated with trajectory data filename.
% NB this file is obsolete, but is used when handling old data.
% Can pass trajData to save loading it.

exptFile = exptDataPath(trajfile);
fprintf('Looking for ExptDat file: %s ',exptFile);
if exist(exptFile,'file')
  fprintf('found\n');
  exptData = struct2cell(load(exptDataPath(trajfile)));
  exptData = exptData{1};
else
  fprintf('not found\n');
  fprintf('Looking for ExptDat inside %s ',trajfile);
  if nargin<2
    trajData = loadTrajData(trajfile);
  end
  if isfield(trajData,'ExptDat')
    exptData = trajData(1).ExptDat;
    fprintf('found\n');
  else
    fprintf('not found.\n');
    fprintf('Trying to generate ExptDat from DB.\n');
    if ~isfield(trajData,'dataProperties') || ...
        ~isfield(trajData(1).dataProperties,'timeLapse')
      fprintf('Missing timeLapse field. Cannot generate ExptDat\n');
      exptData = [];
      return;
    end

    % If absolute path, remove DB data prefix to make relative.
    global dbdatapath;
    if trajfile(1) == filesep
      if isempty(strfind(trajfile,dbdatapath))
        error('Data file must be within DB datapath (%s)',dbdatapath);
      end
      trajfile = strrep(trajfile,[dbdatapath filesep],'');
    end

    conn = dbOpen();
    sql = sprintf(['SELECT name,cellline.name,cellline.code,date FROM experiment '...
                   'JOIN cellline ON cellline_id=cellline.id '...
                   'WHERE file = ' interpString('s') ...
                   ';'],trajfile);
    results = fetch(conn.conn,sql);
    if isempty(results)
      fprintf('No name known for %s. Cannot generate ExptDat\n',trajfile);
      exptData = [];
    else
      row = results(:,1);
      exptData.name = row{1};
      exptData.cellLine = row{2};
      exptData.cellLineCode = row{3};
      exptData.date = row{4};
      exptData.deltat = trajData(1).dataProperties.timeLapse;
      exptData.sourceFile = trajfile;
    end
  end
end
