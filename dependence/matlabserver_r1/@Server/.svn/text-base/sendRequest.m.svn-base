% SERVER.SENDREQUEST sends an RPC request to a slave.
function sendRequest(server, slaveIdx, numArgsOut, reqHook, varargin)
  if (slaveIdx > server.slaveCount)
    error('Slave index is out of bounds.');
  end

  % set up output stream
  req.hook = reqHook;
  req.vars = varargin;
  req.nargout = numArgsOut;

  % set up output stream, send object
  if (server.options.emulate)
    server.savedObjects{slaveIdx} = matlab2java(req);
  else
    if (slaveIdx > length(server.slave_sock))
      error('No socket for slave.');
    end

    os=server.slave_sock{slaveIdx}.getOutputStream();
    oos=java.io.ObjectOutputStream(os);
    oos.writeObject(matlab2java(req));
  end
  