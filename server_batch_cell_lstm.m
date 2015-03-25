function [inerr,dw ] = server_batch_cell_lstm(w, server)
 
  [inerr,dw] = server.rpcsum('batch_cell_lstm', w);
  inerr=inerr/server.slaveCount;
  dw=dw/server.slaveCount;

  end
