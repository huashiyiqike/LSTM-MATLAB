% SERVER represents a handle to a server instance.
% 
% To initialize a server, use:
%
% s = Server(options);
%
% See help for Server.Server and Server.rpc for usage.
classdef Server < handle

properties
  slaveCount
  serv_sock
  slave_processes
  slave_sock
  options
  hostname
  rootpath
  savedObjects
end

methods

function server = Server(options)
% SERVER.SERVER is the constructor for a server instance.
%
% This initializes the server instance using the provided options
% (documented below).  Server() will block until all of the slaves have
% connected.  After it returns, use Server.rpc() to call remote functions.
%
%'options' is a struct containing configuration information and
% must include at least one of options.slavelist or options.slavecount.
% You can launch the slave instances of MATLAB by hand, or use the
% slaveRun.sh script.  The function returns a handle to the
% server state.  The server object is then used to perform operations on the slaves.  
%
% OPTIONS:
%
% options.slavecount
%
% options.port (default=10000)
% Port on which server will listen for slave connections.  If the server gets orphaned or you
% didn't destroy the server properly with serverDestroy(), then this may complain that a port
% is in use.  Restarting the server MATLAB instance will fix the problem.
%
% options.timeout (default=5000)
% Time (in milliseconds) for timeout of server socket.  This affects how frequently you
% can Ctl-C the server while it's waiting for slaves.  The clock resets each time a slave
% connects.
%
% options.retries (default=forever)
% Number of times to retry the accept() call to wait for a client.  By default, the server
% waits forever (i.e., until the user Ctl-C's the function or the clients all connect).  For
% batch jobs, don't forget to set this to something reasonable!
%
% options.slavedir (default = `pwd`)
% Working directory on the slave.  The slaves will all 'cd' to this directory after connecting.
%
% options.startslaves
% If nonzero, serverInit will attempt to start the slaves on its own.  This is presently
% a bit unstable but will hopefully make batch jobs easier in the future.
% 
% options.slavepath (default = setup_paths())
% When options.startslaves is set, specifies a single path string passed to addpath() before
% the slaves are started.  This is usually the path to the matlabserver/ directory (which includes
% the slaveRun.m file needed by the slaves.)
%
% options.slavelist 
% When options.startslaves is set, contains a cell array of host names of all the slaves to start.

  import java.io.*;
  import java.net.ServerSocket;
  import java.net.Socket;

  rootpath=setup_paths();
  
  if (~isfield(options, 'emulate'))
    options.emulate = 0;
  end
  if (~isfield(options, 'startslaves'))
    options.startslaves = 0;
  end
  if (~isfield(options, 'matlabpool'))
    options.matlabpool = 0;
  end
  if (~isfield(options, 'timeout'))
    options.timeout = 5000; % 5 second timeout
  end
  if (~isfield(options, 'retries'))
    options.retries = 100000; % try for a really long time
  end
  if (~isfield(options, 'port'))
    options.port = 10000;
  end
  if (~isfield(options, 'slavedir'))
    options.slavedir=pwd;
  end
  if (~isfield(options, 'slavepath'))
    options.slavepath=rootpath;
  end
  if (~isfield(options, 'slavecount'))
    if (~isfield(options, 'slavelist'))
      error('Must provide options.slavelist cell array or options.slavecount.');
    elseif (options.emulate)
      error('Must provide options.slavecount when "emulate" is used.');
      options.slavecount = length(options.slavelist);
    end
  else
    if (isfield(options, 'slavelist'))
      if (options.slavecount ~= length(options.slavelist))
        error('options.slavelist doesn''t match options.slavecount.');
      end
    end
  end
  if (options.startslaves)
    if (~isfield(options, 'slavelist'))
      error('Must provide options.slavelist cell array if using options.startslaves.');
    end
  end
  slaveCount = options.slavecount;
  server.slaveCount=slaveCount;
  server.options = options;
  server.rootpath = rootpath;  

  if (options.emulate)
    % do nothing.
    
  else % emulate == 0
  
  % get local hostname
  addr=java.net.InetAddress.getLocalHost();
  hostname=char(addr.getHostName());
  server.hostname=hostname;
  
  % Open server socket
  server.serv_sock = ServerSocket(options.port, slaveCount);
  server.serv_sock.setReuseAddress(true);
  if (options.timeout > 0)
    server.serv_sock.setSoTimeout(options.timeout);
  end

  try
  
    % start up slaves
    if (options.startslaves)   
      RT = java.lang.Runtime.getRuntime();
      for i = 1:slaveCount
        if (strcmp(options.slavelist{i}, 'localhost') == 1)
          cmd=sprintf('matlab -nodesktop -nosplash -r addpath(''%s''),slaveRun(''%s'',%d),quit;', options.slavepath, hostname, options.port);
          server.slave_process{i}=RT.exec(cmd, '', File(options.slavedir));
        else
          cmd=sprintf('ssh %s "matlab -nodesktop -nosplash -r addpath(''%s''),slaveRun(''%s'',%d),quit;"', options.slavelist{i}, options.slavepath, hostname, options.port);
          server.slave_process{i}=RT.exec(cmd);
        end
      end
    end
    
    % wait for slaves to connect; NOTE: slave_sock{i} and slave_process{i}
    % may not correspond.
    for i=1:slaveCount
      for r=1:options.retries
        try
          % accept connection from slave
          server.slave_sock{i} = server.serv_sock.accept();
          break ;
        catch
          % timeout
          if (r < options.retries)
            fprintf(1,'Waiting for slave to connect... %d/%d\n',i, server.slaveCount);
          else
            display('Timed out waiting for slaves.');
            rethrow(lasterror);
          end
        end
      end 
    end

    % all are connected; close listener.
    server.serv_sock.close();

    try
      % exchange info with clients
      display('Handshaking...');
      slaveinfo.workdir = options.slavedir;
      server.rpc('handshake', {slaveinfo});
 
      % start matlabpool sequentially...
      if (options.matlabpool ~= 0)
        for i=1:server.slaveCount
          fprintf(1, 'Starting matlabpool on slave %d...', i);
          server.sendRequest(i, 0, 'matlabpool');
          dummy=server.getReply(i);
        end
      end
    catch
      display('Handshake failed.');
      rethrow(lasterror);
    end
    
  catch
    delete(server);
    server=[];
    rethrow(lasterror);
  end
  
  end % if options.emulate == 0
end

function clearReplies(server)
  if (isfield(server, 'slave_sock'))
    for i=1:length(server.slave_sock)
      server.slave_sock{i}.setSoTimeout(200);
      try
        server.getReply(i);
      end
      server.slave_sock{i}.setSoTimeout(0);
    end
  end
end


function delete(server)
% SERVER.DELETE destroys a server instance.
%
% This closes the listening socket, all slave sockets, and terminates any
% launched slave processes.

  fprintf(1, 'Destroying server on %s:%d.\n', ...
          server.hostname, server.options.port);

  if (isfield(server, 'serv_sock'))
    server.serv_sock.close();
  end
  
  if (isfield(server, 'slave_sock'))
    for i=1:length(server.slave_sock)
      server.slave_sock{i}.close();
    end
  end
  
  if (isfield(server, 'slave_process'))
    display('Shutting down slaves...');
    for i=1:length(server.slave_process)
      server.slave_process{i}.destroy();
    end
  end

end

end % end methods

end
