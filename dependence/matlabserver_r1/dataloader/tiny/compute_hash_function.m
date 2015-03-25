function out = compute_hash_function(words,hash_key)
  
if (nargin==1)
  rand('state',0);
  hash_key = rand(1,1000);
end

if ~iscell(words)
  words = {words};
end

for a=1:length(words)
  
  out(a) = sum( hash_key(1:length(words{a})) .* double(uint8(words{a})) );
  
end
 
