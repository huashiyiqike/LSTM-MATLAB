function [X, imageDim] = slaveLoadTinyBatch(tinyFileName, batchStart, batchSize)
  
  idx=batchStart:batchStart+batchSize-1;
  X = loadTinyImages(idx, tinyFileName);
  X = double(reshape(X, 32*32*3, length(idx))');

  imageDim = [32 32 3];
  %X = slaveRef(X);
