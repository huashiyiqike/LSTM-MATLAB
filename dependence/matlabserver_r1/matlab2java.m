function javaVal = matlab2java(matlabVal)

  
  fieldType=class(matlabVal);
  if (strcmp(fieldType, 'struct') == 1)
    if (numel(matlabVal) > 1)
    %  display('Warning: Can''t yet serialize structure arrays.');
    end
  end
  if (strcmp(fieldType, 'slaveRef') == 1)
    if (numel(matlabVal) > 1)
      error('Error: Can''t yet serialize slaveRef arrays.');
    end
  end
  
  switch fieldType
   case 'function_handle'
    javaVal=makePair(1, ['@' func2str(matlabVal)]);

   case 'struct'
    arr=java.util.Vector();
    arr.add(0, size(matlabVal));
    for k=1:numel(matlabVal)
      % convert each struct...
      struc=java.util.HashMap();
      fields=fieldnames(matlabVal(k));
      for i=1:length(fields)
        val=matlabVal(k).(fields{i});
        struc.put(fields{i}, matlab2java(val) );
      end
      arr.add(k, struc);
    end
    javaVal=makePair(2, arr);

   case 'cell'
    arr=java.util.Vector();
    arr.add(0, size(matlabVal));
    for i=1:numel(matlabVal)
      arr.add(i, matlab2java(matlabVal{i}));
    end
    javaVal=makePair(3, arr);

   case 'slaveRef'
    javaVal=makePair(6, int32(matlabVal));

   case 'serverRef'
    % convert serverRef to slave ref silently.
    javaVal=makePair(6, int32(matlabVal.unwrap()));

   case {'double','single','int32','int16','int8','uint32','uint16','uint8','char','logical'}
    arr=java.util.Vector();
    arr.add(0, size(matlabVal));
    arr.add(1, matlabVal);
    javaVal=makePair(4, arr);

   otherwise
    if (strfind(fieldType, 'java') == 1)
      javaVal=makePair(5,matlabVal);
    else
      error(['Unrecognized field type: ' fieldType]);
    end
  end

function p = makePair(id, obj)
  p = java.util.Vector();
  p.add(0,int32(id));
  p.add(1,obj);
