% SLAVERUN runs a standard slave processing loop using a single call.
%
% slaveRun(hostname,port) initializes the slave by calling
% slaveInit(hostname,port), then enters a loop calling slaveProcessRequest()
% forever.  This function is usually the only function called on a slave,
% and is often given to MATLAB as a batch command using the -r switch.
function slaveRun(hostname, port, continueOnError)
 
  if (nargin < 3)
    continueOnError = 0;
  end
  
  slave=Slave(hostname, port);

  while (1)
    try 
      Slave.processRequest(slave);
    catch
      display(lasterr);
      if (continueOnError == 0)
        rethrow(lasterror);
      end
    end
  end
  