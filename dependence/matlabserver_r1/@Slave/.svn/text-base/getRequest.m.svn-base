% SLAVE.GETREQUEST waits for and then returns a request from the server.
function req = getRequest(slave)

  % this blocks until server creates output stream
  slave.sock.setSoTimeout(2000);
  while(1)
    try 
      is=java.io.ObjectInputStream(slave.sock.getInputStream());
      break;
    end
  end
  
  % block until we get a new message;  convert to MATLAB
  slave.sock.setSoTimeout(2000);
  while(1)
    try 
      req = java2matlab(is.readObject());
      break;
    end
  end

  