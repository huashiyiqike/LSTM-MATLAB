% SERVER.GETREPLY gets a reply structure stored by the slave with given index.
function result = getReply(server, slaveIdx)

  if (slaveIdx > server.slaveCount)
    error('Slave index is out of bounds.');
  end

  if (server.options.emulate)
    % emulate the following:
    % 1.  deserialization of data by slave
    % 2.  processing of request by slave
    % 3.  serialization of reply by slave.
    % 4.  de-serialization of reply by server.
    
    % Deserialize request
    reply = emulateSlaveProcessRequest(server, slaveIdx);
  else
    if (slaveIdx > length(server.slave_sock))
      error('No socket for slave');
    end
    sock=server.slave_sock{slaveIdx};
    
    % this blocks until slave creates output stream
    is=java.io.ObjectInputStream(sock.getInputStream());
    % block until we get a new message;  convert to MATLAB
    reply = java2matlab(is.readObject());
  end
  
  result=reply.result;
  if (isfield(reply, 'error'))
    rethrow(reply.error);
  end

  % wrap any slaveRef objects in a serverRef...
  result = serverRef.wrapSlaveRefs(result, server, slaveIdx);
