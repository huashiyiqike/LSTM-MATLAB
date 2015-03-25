% SOFTMAXLOSS Computes softmax loss on slaves connected to given server
% context.
%
% server is the server handle.
%
% w, X, y, K, and (optionally) LAMBDA are all passed to the slaves.
% The returned results from the slaves are summed up and
% returned to the caller.
%
% Returns the total negative log likelihood and sum of gradients from each
% slave.
%
% Example:
%
%  For an MxN data matrix X and Mx1 label vector y and K classes:
%
%  w = minFunc(@softmaxLoss, zeros(1,(K-1)*N), server, X, y, K);
%
%  Note that X and y can be slave references or raw data.
function [nll, g, H] = softmaxLoss(w, server, X, y, K, LAMBDA)
  if (nargin < 6)
    LAMBDA = 0;
  end

  [nll,g] = server.rpcsum('slaveSoftmaxLoss', w, X, y, K, LAMBDA);
  
  if (nargout == 3)
    error('Hessian not implemented.');
  end
  
