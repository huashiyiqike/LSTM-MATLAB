function matlabVal = java2matlab(javaVal)


  if (strcmp(class(javaVal), 'java.util.Vector') == 1)
    if (javaVal.size() ~= 2)
      error('Incorrect Vector size (~= 2)');
    end
    fieldType=javaVal.get(0);
    value=javaVal.get(1);

    switch fieldType
     case 1 % function_handle
      matlabVal=str2func(value(2:end));

     case 2 % struct
      if (strcmp(class(value), 'java.util.Vector') == 0)
        error('Struct array value is not a java.util.Vector');
      end
      if (value.size() < 1)
        error('Struct array is empty.');
      end
      dim = value.get(0);
      matlabVal=struct('x', cell(dim'));
      matlabVal=rmfield(matlabVal, 'x');

      for k=1:numel(matlabVal)
        struc = value.get(k);
        keys= struc.keySet();
        iterator=keys.iterator();

        while iterator.hasNext()
          key=iterator.next();
          val=struc.get(key);
          matlabVal(k).(key)=java2matlab(val);
        end
      end

     case 3 % cell
      if (strcmp(class(value), 'java.util.Vector') == 0)
        error('Cell array value is not a java.util.Vector');
      end
      if (value.size() < 1)
        error('Java cell-array vector is empty.');
      end
      dim=value.get(0);
      matlabVal=cell(dim');
      if (value.size() < numel(matlabVal)+1)
        error('Java cell-array vector is too small.');
      end
      for i=1:numel(matlabVal)
        matlabVal{i} = java2matlab(value.get(i));
      end

     case 4 % matlab matrix
      if (strcmp(class(value), 'java.util.Vector') == 0)
        error('Matrix value is not a java.util.Vector');
      end
      if (value.size() < 1)
        error('Java matrix vector is empty.');
      end
      dim=value.get(0);
      matlabVal=reshape(value.get(1), reshape(dim,1,length(dim)));
      
     case 5 % java
      matlabVal = value;

     case 6 % slaveRef
      matlabVal = slaveRef([], value);

    end
  else
    matlabVal = javaVal;
  end