% SERVERREF is a wrapper for slave references that ensures their deletion
% after the server releases them.  Do not create instances of this class directly.
classdef serverRef < handle

properties (SetAccess = private)
  slaveIdx;
  server;
end
properties (SetAccess = private, GetAccess = private)
  remoteRef;
end

methods

function hdl = serverRef(server, slaveIdx, H)
  hdl.server = server;
  hdl.slaveIdx = slaveIdx;
  hdl.remoteRef = H;
end

function delete(hdl)
  fprintf(1, 'Deleting reference %d on slave %d\n', int32(hdl.remoteRef), hdl.slaveIdx);
  try
    hdl.server.sendRequest(hdl.slaveIdx, 0, 'slaveRefDelete', hdl.remoteRef);
    hdl.server.getReply(hdl.slaveIdx);
  end
end

function ref = unwrap(hdl)
% SERVERREF.UNWRAP is called internally to unwrap outgoing serverRefs.
  ref = hdl.remoteRef;
end

end % end methods


methods (Static)

function outvar = wrapSlaveRefs(var, server, slaveIdx)
% SERVERREF.WRAPSLAVEREFS is called internally to wrap incoming slaveRefs
% with serverRefs.  Do not call this yourself.
  
  type=class(var);
  switch (type)
   case 'struct'
    if (length(var) > 1)
      % struct array
      for i=1:length(var)
        outvar(i) = serverRef.wrapSlaveRefs(var(i), server, slaveIdx);
      end
    else
      % single struct
      fields=fieldnames(var);
      for i=1:length(fields)
        outvar.(fields{i}) = serverRef.wrapSlaveRefs(var.(fields{i}), server, slaveIdx);
      end
    end
    
   case 'cell'
    % cell array
    for i=1:length(var)
      outvar{i} = serverRef.wrapSlaveRefs(var{i}, server, slaveIdx);
    end

   case 'slaveRef'
    for i=1:length(var)
      outvar(i) = serverRef(server, slaveIdx, var(i));
    end

   otherwise
    outvar=var;
  end
end
  
end % end methods (Static)



end
