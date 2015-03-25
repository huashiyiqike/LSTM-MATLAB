clear
addpath(genpath('./dependence'))
addpath([pwd '/data/'])

format long

result.resume = 0;
result.savemat         =   0;
result.savepic         =   0;
result.savePath = './results/';
result.dataPath = './data/';
result.picPath =  './pic/';
result.linespec = {'r.-','b*-','go-','rs-','b^-','gd-','r--'};

speed.usegpu = 'cpu_double'; 
speed.usecluster =0;
speed.numcluster=4;
speed.machine = 'lqc';
speed.gradientchecking= 0;

options.maxIter =  1e5  ;
options.display = 'off';
options.LS_init = 2;
options.maxFunEvals =50;  
options.Corr = 10; 
% options.optTol = 1e-66;
% options.TolX =1e-66;
% options.TolFun=1e-66;

problem.name='adding';
problem.datapath='/home/lq/timit/';
problem.numsamples=20000 ; %  not enough
problem.batchsize= 200 ; % not enough
problem.T= 8;
problem.Ttest= problem.T ;
problem.numtest=3000;
problem.gate_size       = 2; 

problem.numMmcell=2;
problem.continualPredict=0;
problem.bias1 = 1; % other bias
problem.bias2 = 1; % output bias

sgd.alpha = 0.1;
sgd.momentum = 0.9;
 
Main(result,speed,options,problem,sgd)




