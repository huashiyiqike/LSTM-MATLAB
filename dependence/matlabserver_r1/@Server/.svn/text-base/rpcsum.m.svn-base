% SERVER.RPCSUM invokes an RPC, then sums the results from each slave.
% The sum is performed independently for each parameter.
function varargout = rpcsum(server, reqHook, varargin)
  
  argsout = cell(1, nargout);
  [argsout{:}] = server.rpc(reqHook, varargin{:});

  for i=1:length(argsout)
    sz = size(argsout{i}{1});
    % convert to columns
    argsout{i} = cellfun(@(X) X(:), argsout{i}, 'UniformOutput', false);
    % cat columns, sum, reshape to original size
    argsout{i} = reshape(sum(cell2mat(argsout{i}), 2), sz);
  end
  varargout = argsout;
