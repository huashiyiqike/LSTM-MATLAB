% SLAVE.SENDREPLY sends a reply to the server (or an error)
function sendReply(slave, result, err)

  reply.result=result;
  if (nargin >= 3)
    reply.error=err;
  end
  
  os=slave.sock.getOutputStream();
  oos=java.io.ObjectOutputStream(os);
  oos.writeObject(matlab2java(reply));
