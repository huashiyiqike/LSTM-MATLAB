classdef slaveRef < int32

methods

function H = slaveRef(data, hidx)
  global state;

  if (~isfield(state, 'refs'))
    state.refs=cell(1,10);
  end
  if (~isfield(state, 'refs_occupancy'))
    state.refs_occupancy=zeros(1,10);
  end

  if (nargin < 2)
    I=find(state.refs_occupancy == 0);
    if (length(I) == 0)
      hidx = int32(length(state.refs)+1);
    else
      hidx = int32(I(1));
    end
  end

  % generate ref
  H = H@int32(hidx);

  if (nargin < 2)
    % store to global repo
    state.refs{hidx} = data;
    state.refs_occupancy(hidx) = 1;
  end
end

function v = getValue(H)
  global state;
  if (state.refs_occupancy(int32(H)) == 0)
    error('Dereferencing invalid slaveRef.');
  end
  v = state.refs{int32(H)};
end

end % end methods

methods (Static)

function outvar = dereferenceVar(var)
  
  type=class(var);
  switch (type)
   case 'struct'
    if (length(var) > 1)
      % struct array
      for i=1:length(var)
        outvar(i) = slaveRef.dereferenceVar(var(i));
      end
    else
      % single struct
      fields=fieldnames(var);
      for i=1:length(fields)
        outvar.(fields{i}) = slaveRef.dereferenceVar(var.(fields{i}));
      end
    end
    
   case 'cell'
    % cell array
    for i=1:length(var)
      outvar{i} = slaveRef.dereferenceVar(var{i});
    end

   case 'slaveRef'
    outvar = var.getValue();

   otherwise
    outvar=var;
  end
end
  
end % end methods (Static)

end

