% RPC processes requests to the slaves.  It is the main mechanism by which
% the server communicates with the slaves and has a "remote procedure
% call"-like interface.
%
% rpc(reqHook, ...) runs the function identified by the string 'reqHook' on
% all of the slaves with the arguments that follow.
%
% The arguments that follow reqHook are passed in the same order as the
% arguments would be passed to the function if it were called locally.
% However, each argument represents an array of arguments passed to the
% various slaves.  In particular, for a server with N slaves, each argument
% is expected to be a cell array of N entries, where the i'th entry of the
% array contains the argument given to the i'th slave.  Several additional
% special cases are handled for convienience: (i) If the argument is not a
% cell array, it is wrapped in a cell array by arg={arg}, and (ii) If the
% argument is a singleton (as produced by (i), or is a cell array with only
% 1 element), the argument is replicated for all N slaves.
%
% Thus, for a 2 slave system, the following function calls are all identical:
%
% server.rpc('zeros', 3,1);
% server.rpc('zeros', {3},{1});
% server.rpc('zeros', {3,3},{1,1});
%
% [result1, ...] = server.rpc(...) works as above, but returns in
% result1, ... the results of the remote function calls.  The results are
% in the same order as the results returned by the remote function, but as
% with arguments, they are cell arrays containing a single result per slave.
%
% Example for 2 slaves:
%
% Z = server.rpc('zeros', 1,3);
% Z
%    Z = [ 1x3 double ]   [ 1x3 double ]
% Z{1}
%    ans = 0  0  0
%
% Caveat:
%
% At present, if server.rpc is invoked without output arguments
% the system will not retrieve any outputs from the remote function call.
% Thus, whereas MATLAB normally returns the first output (and prints the
% result) when no outputs are given this function will return nothing.
%
function varargout = rpc(server, reqHook, varargin)

  if (nargin >= 3)
    
    % check arguments and convert type if necessary
    for j=1:length(varargin)
      if (length(varargin{j}) == 0)
        error(['Empty argument array for argument ' num2str(j)]);
      end
      if (~isa(varargin{j}, 'cell'))
        varargin{j} = {varargin{j}};
      end
    end
 
    % rearrange arguments to be per-slave
    for i=1:server.slaveCount
      for j=1:length(varargin)
        if (length(varargin{j}) == 1)
          slaveVars{i}{j} = varargin{j}{1};
        else
          slaveVars{i}{j} = varargin{j}{i};
        end
      end
    end

    % send request to each slave
    for i=1:server.slaveCount
      if (~isempty(slaveVars{i}))
        server.sendRequest(i, nargout, reqHook, slaveVars{i}{:});
      else
        server.sendRequest(i, nargout, reqHook);
      end
    end
    
  else

    % send request to each slave;  no args
    for i=1:server.slaveCount
      server.sendRequest(i, nargout, reqHook);
    end
  end

  % get replies from each slave
  errCount=0;
  for i=1:server.slaveCount
    try
      slaveResults{i}=server.getReply(i);
    catch
      err=lasterror;
      err.message = sprintf('Error from slave %d:\n%s', i, err.message);
      errCount = errCount+1;
    end
  end
  if (errCount > 0)
    err.message = sprintf('%s\n\n %d slaves returned errors.', err.message, errCount);
    rethrow(err);
  end


  % reformat result
  for j=1:nargout
    varargout{j}={};
    for i=1:server.slaveCount
      varargout{j}{i} = slaveResults{i}{j};
    end
  end
