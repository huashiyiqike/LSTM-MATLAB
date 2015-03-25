% SLAVE.PROCESSREQUEST processes a single request from the server.
%
% This function is the standard mechanism for interacting with the server.
% It retrieves a single request, executes the requested function, then copies
% the results of the function back to the server before returning.
function processRequest(slave)

  req = slave.getRequest();
  
  try
    % req.hook is the name of the hook to run.
    % req.vars is a cell array of variables.
    % req.nargout is expected number of results in caller
    
    % decide whether to dereference slaveRefs (hooks can override)
    dereference=1;
    if (isfield(slave.hooks,req.hook))
      hook = slave.hooks.(req.hook);
      if (isfield(hook,'noDereference') & (hook.noDereference ~= 0))
        dereference = 0;
      end
    end

    % translate any slaveRef objects
    if (dereference)
      if (length(req.vars) > 0)
        req.vars = slaveRef.dereferenceVar(req.vars);
      end
    end
   
    % check for custom handler
    if (isfield(slave.hooks,req.hook))
      hook = slave.hooks.(req.hook);
      if (strcmp(class(hook.func), 'function_handle') == 1)

        if (req.nargout ~= 0)
          % server called with non-zero number of outputs
          result=cell(1,req.nargout);        
          if (isfield(hook, 'userData'))
            [result{:}] = hook.func(hook.userData, req.vars{:});
          else
            [result{:}] = hook.func(req.vars{:});
          end
        else
          % server called with no output args
          if (isfield(hook, 'userData'))
            hook.func(hook.userData, req.vars{:});
          else
            hook.func(req.vars{:});
          end
          result=[]; % return a null response no matter what.
        end
        slave.sendReply(result);
      else
        error(['Slave hook ' req.hook ' is not valid.']);
      end
    else
      % no handler;  try to call function directly
      func = str2func(req.hook);
      if (req.nargout ~= 0)
        % non-zero output args
        result=cell(1,req.nargout);        
        [result{:}]=func(req.vars{:});
      else
        % no output args
        func(req.vars{:});
        result=[];
      end
      slave.sendReply(result);
    end

  catch
    slave.sendReply([], lasterror);
    rethrow(lasterror);
  end
