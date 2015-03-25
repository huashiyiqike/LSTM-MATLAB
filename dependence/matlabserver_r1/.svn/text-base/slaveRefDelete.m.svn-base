function slaveRefDelete(H)
  global state;
    
  if (~isfield(state, 'refs'))
    state.refs=cell(1,10);
  end
  if (~isfield(state, 'refs_occupancy'))
    state.refs_occupancy=zeros(1,10);
  end

  if (strcmp(class(H), 'slaveRef') == 1)
    state.refs{int32(H)} = [];
    state.refs_occupancy(int32(H)) = 0;
  else
    error('Invalid argument class.');
  end
