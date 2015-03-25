% Computes softmax loss and gradient for data in state.(Xstorage) and labels
% in state.(ystorage) where there are K classes.  w is the weight matrix
% with K-1 columns as a vector.
function [nll, g] = slaveSoftmaxLoss(w, X, y, K, LAMBDA)
  if (nargin < 5)
    LAMBDA = 0;
  end

  [M,N] = size(X);
  theta = reshape(w, N, K-1);
  I=sparse(1:M,y,1,M,K);
  W=[exp(X * theta), ones(M,1)]; % last col is exp(X*0)
  P=bsxfun(@rdivide, W, sum(W,2));
  g=X'*(P - I);
  g=reshape(g(:,1:K-1), (K-1)*N,1) + LAMBDA * w;
  nll=-full(sum(log(sum(I .* P, 2)))) + LAMBDA * 0.5 * sum(w.^2);
