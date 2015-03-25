% SLAVEHOOK installs a 'hook' into the slave structure which overrides
% function calls made to the named hook.
%
% slave.hook(hookName, func, userData, noDeref) inserts a hook into the
% slave structure which will be called whenever the slave receives a request
% to call the function with name hookName.  func is the function handle to
% be called and userData is an optional argument whose value is passed as
% the first argument of func, followed by the arguments from the server.
%
% This can be used to override matlab functions or other functions that
% might be called by the server and replace them with more RPC-friendly
% semantics, etc.  For instance, by default, all slaves include an 'exit'
% hook that allows the server to call the 'exit' function as usual, but
% which cleanly destroys the slave state before closing (whereas calling
% MATLAB's exit() directly would quit the slave without cleaning up).
% if 
%
function hook(slave, hookName, func, userData, noDeref)

  slave.hooks.(hookName).func = func;

  if ((nargin > 3) & (~isempty(userData)))
    slave.hooks.(hookName).userData = userData;
  end

  if (nargin < 5)
    noDeref = 0;
  end
  slave.hooks.(hookName).noDereference = noDeref;
