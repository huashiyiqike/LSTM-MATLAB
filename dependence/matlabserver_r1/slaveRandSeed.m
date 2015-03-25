function slaveRandSeed(seed)
  
  f=fopen('/dev/urandom', 'r');
  seed = fread(f, 1, 'uint32');
  fclose(f);
  
  RandStream.setDefaultStream(RandStream('mt19937ar', 'Seed', seed));
