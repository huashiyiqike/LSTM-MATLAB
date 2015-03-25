function result = emulateSlaveProcessRequest(server, slaveIdx)

% emulates the following:
% 1.  deserialization of data by slave
% 2.  processing of request by slave
% 3.  serialization of reply by slave.
% 4.  de-serialization of reply by server.

  % construct an imaginary slave context
  hooks.exit.func = @exit;
  hooks.exit.noDereference = 0;
  hooks.slaveRefDelete.func = @slaveRefDelete;
  hooks.slaveRefDelete.noDereference = 1;
  slave.hooks = hooks;
 
  % hook slave functions to get/set stored data
  slave.getRequest=@() java2matlab(server.savedObjects{slaveIdx}); %(1)
  slave.sendReply=@(varargin) emulateReply(server, slaveIdx, varargin{:}); %(3)
  
  % process request
  Slave.processRequest(slave); %(2)

  % deserialize reply
  result = java2matlab(server.savedObjects{slaveIdx}); %(4)

function emulateReply(server, slaveIdx, result, err)
  reply.result=result;
  if (nargin >= 4)
    reply.error=err;
  end
  server.savedObjects{slaveIdx} = matlab2java(reply);
