function [in_size,gate_size,out_size,share_size,share_size2,numMmcell,W,in,ingate,cellstate,cells,outgate,...
    node_outgateInit,cellinInit,node_cellbiasInit,delta_outInit,cellstatusInit]=netInit(problem)
global mones  mzeros  
switch problem.name
    case  'tempor'
        in_size = 8 ; out_size=3;
    case 'walking'
        in_size=49;out_size=in_size;
    otherwise
        in_size = 2; out_size =1;
end
node_outgateInit=cell(1,problem.T);
cellinInit=node_outgateInit;
node_cellbiasInit=node_outgateInit;
delta_outInit= node_outgateInit;
cellstatusInit=node_outgateInit;

gate_size=problem.gate_size ;
for i=1:problem.T
    node_outgateInit{i}=0.5*mones(problem.batchsize,gate_size);
    cellinInit{i}=mzeros(problem.batchsize,problem.numMmcell*gate_size);
    node_cellbiasInit{i}=mones(problem.batchsize,1);
    delta_outInit{i}=mzeros(problem.batchsize,out_size);
    cellstatusInit{i}=mzeros(problem.batchsize,problem.numMmcell*gate_size);
end
bias1=problem.bias1 ; % other bias
bias2=problem.bias2 ; % output bias
ingatebias = -1;


numMmcell=problem.numMmcell;

in_size=in_size+bias1;
% share_size include ingate, status, outgate, cellout 
share_size = in_size + gate_size * (2+2*problem.numMmcell) ; 
share_size2 = gate_size*share_size;
% share_size2 is weights for a layer of lstm, lstm has 4 layer: ingate, cell
% outgate, out ,added up to psize
psize = 2*share_size2 +share_size2*numMmcell + (gate_size*numMmcell+1)*out_size;

node_size = in_size   +gate_size * (2+2*problem.numMmcell)  + out_size + bias2;
nodeindex = 1 : node_size;
in = nodeindex (1: in_size   );
ingate  = nodeindex ( in_size +1: in_size + gate_size );
cellstate    = nodeindex ( in_size + gate_size + 1 : in_size + (1+problem.numMmcell) * gate_size   );
cells =  nodeindex ( in_size + (1+problem.numMmcell) * gate_size + 1: in_size +  (1+2*problem.numMmcell) * gate_size   );
outgate = nodeindex ( in_size +  (1+2*problem.numMmcell)  * gate_size + 1: in_size +   (2+2*problem.numMmcell)  * gate_size   );


W =   1e-4 *  (mod( fix( 2^50  *  rand(psize,1    ) ) , 2000 )    -1000);

for i=1:psize /gate_size
    W( ceil(rand*psize) )=0;
end

[ Wingate,Wcell , Woutgate, Wout]=unpack(W);
Wingate(in(end),:)=Wingate(in(end),:)+ingatebias;
W=pack(Wingate,Wcell , Woutgate, Wout);
    function [W]=pack(Wingate,Wcell , Woutgate,Wout)
        W = [Wingate(:);Wcell(:) ;Woutgate(:);Wout(:)];
    end
    function [Wingate,Wcell ,Woutgate,Wout] = unpack(W)
        Wingate= reshape( W( 1:share_size2 )   , share_size ,gate_size );
        Wcell  = reshape( W( share_size2 +1 :   share_size2 *(1+numMmcell) ),  share_size, numMmcell*gate_size);
        Woutgate = reshape( W( (1+numMmcell) * share_size2 +1 : (2+numMmcell)* share_size2  ), share_size , gate_size);
        Wout = reshape( W( (2+numMmcell) * share_size2 +1 : end ) ,gate_size*numMmcell+1 ,  out_size);
    end

end