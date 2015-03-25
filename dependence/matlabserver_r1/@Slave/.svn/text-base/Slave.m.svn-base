% SLAVE is a slave instance that connects to a SERVER instance to do work.
% To start a slave, use the slaveRun() method.
classdef Slave < handle

properties
    rootpath
    server_hostname
    server_port
    slave_hostname
    sock
    hooks
end

methods

function slave = Slave(server_hostname, server_port)

  slave.rootpath = setup_paths();

  if (nargin < 2)
    server_port = 10000;
  end

  slave.server_hostname = server_hostname;

  slave.server_port = server_port;
  
  import java.net.Socket;
  import java.io.*;

  addr=java.net.InetAddress.getLocalHost();
  slave.slave_hostname = char(addr.getHostName());
  
  % open connection to server
  slave.sock = Socket(server_hostname, server_port);

  % initialize exit hook
  slave.hook('exit', @Slave.exit, slave);
  slave.hook('handshake', @Slave.handshake);
  slave.hook('slaveRefDelete', @slaveRefDelete, [], 1);

  % process handshake
  Slave.processRequest(slave);
end

function delete(slave)
%  SLAVE.DELETE closes the slave socket before destruction.
  slave.sock.close();
  fprintf(1, 'Destroying slave on %s.\n', slave.slave_hostname);
end

end % end methods

methods (Static)

processRequest(slave)

function dummy_result = exit(slave)
  slave.sendReply([]);
  delete(slave);
  exit ;
end

function result = handshake(slaveinfo)
  cd(slaveinfo.workdir);
  result=1;
end

end % end static methods


end