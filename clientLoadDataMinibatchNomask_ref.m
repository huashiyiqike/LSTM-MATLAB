function [W]=clientLoadDataMinibatchNomask_ref(batchStart, batchEnd, batchsize,problem,speed,data,mask,batchnum)
global  mones mzeros convert in_size gate_size out_size share_size signum usegpu...
    share_size2  in ingate cellstate cells outgate globalData globalMask  numMmcell    ...
    node_outgateInit cellinInit node_cellbiasInit delta_outInit cellstatusInit  ;
[mones,mzeros,convert]=gputype(speed.usegpu);
fprintf('batchStart = %d, batchEnd = %d, batchsize = %d\n', batchStart, batchEnd, batchsize);
usegpu=0; 
[in_size,gate_size,out_size,share_size,share_size2,...
    numMmcell,W,in,ingate,cellstate,cells,outgate,...
    node_outgateInit,cellinInit,node_cellbiasInit,delta_outInit,cellstatusInit]=netInit(problem);

for i=1:problem.T
    node_outgateInit{i}=0.5*mones(problem.batchsize,gate_size);
    cellinInit{i}=mzeros(problem.batchsize,problem.numMmcell*gate_size);
    node_cellbiasInit{i}=mones(problem.batchsize,1);
    delta_outInit{i}=mzeros(problem.batchsize,out_size);
    cellstatusInit{i}=mzeros(problem.batchsize,problem.numMmcell*gate_size);
end

signum =3; 
globalData=data( 1+(batchnum-1)*batchsize :batchnum*batchsize ,:,:);
globalMask=mask(1+(batchnum-1)*batchsize :batchnum*batchsize ,:,:);

end