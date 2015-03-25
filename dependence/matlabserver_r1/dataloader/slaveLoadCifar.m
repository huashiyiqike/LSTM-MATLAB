function [Xtrain, Ytrain, Xtest, Ytest, imageDim] = slaveLoadCIFAR(cifarFileDir, numSlaves, slaveIndex)
  

  % params
  samplesPerFile = 10000;
  numTrainFiles=5;
  numTestFiles=1;

  % compute numbers of samples
  trainSamplesPerSlave = samplesPerFile * numTrainFiles / numSlaves;
  trainIndex = 1:samplesPerFile*numTrainFiles;
  testSamplesPerSlave = samplesPerFile * numTestFiles / numSlaves;
  testIndex = 1:samplesPerFile*numTestFiles;

  % choose indices for this slave
  firstTrainSample = floor(trainSamplesPerSlave * (slaveIndex-1))+1;
  lastTrainSample = floor(trainSamplesPerSlave * (slaveIndex));
  myTrainIndices = trainIndex(firstTrainSample:lastTrainSample);

  firstTestSample = floor(testSamplesPerSlave * (slaveIndex-1))+1;
  lastTestSample = floor(testSamplesPerSlave * (slaveIndex));
  myTestIndices = testIndex(firstTestSample:lastTestSample);
  
  
  % load training data
  Xtrain = zeros(length(myTrainIndices), 3072);
  Ytrain = zeros(length(myTrainIndices), 1);
  for i=1:numTrainFiles
    firstFileSample = samplesPerFile*(i-1)+1;
    fileIndices = firstFileSample : samplesPerFile*i;
    myFileIndices = intersect(fileIndices, myTrainIndices);

    if (length(myFileIndices) > 0)
      fname = sprintf('%s/data_batch_%d.mat', cifarFileDir, i);
      f = load(fname);
      Xtrain(myFileIndices - firstTrainSample + 1, :) = f.data(myFileIndices - firstFileSample + 1, :);
      Ytrain(myFileIndices - firstTrainSample + 1) = double(f.labels(myFileIndices - firstFileSample + 1)) + 1;
    end
  end

  % load test data
  fname = sprintf('%s/test_batch.mat', cifarFileDir);
  f = load(fname);
  Xtest = double(f.data(myTestIndices, :));
  Ytest = double(f.labels(myTestIndices)) + 1;

  imageDim = [32 32 3];

  Xtrain=slaveRef(Xtrain);
  Ytrain=slaveRef(Ytrain);
  Xtest=slaveRef(Xtest);
  Ytest=slaveRef(Ytest);
  
  

