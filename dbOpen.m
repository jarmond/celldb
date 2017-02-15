function connC=dbOpen()
% Open database and return connection

global dbsystem;
switch dbsystem
  case 'mysql'
    db = 'ktdynamics';
    user = db;
    password = 'ktmcmc';
    [~,node] = system('hostname');
    node = strsplit(node,'.');
    node = node{1};
    if strcmp(node,'node001')
      server = 'localhost';
    else
      server = 'node001';
    end
    conn = database(db,user,password,'Vendor','MySQL','Server',server);

  case 'sqlite'
    conn = database('','','','org.sqlite.JDBC','jdbc:sqlite:/Users/jon/kt/db/kt.db');

  otherwise
    error(['Unknown DB system: ' DBSYSTEM]);
end

C = onCleanup(@() close(conn));
connC.conn = conn;
connC.C = C;

