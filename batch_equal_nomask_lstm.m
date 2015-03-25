function [inerr,dw,inLL,right ]=batch_equal_nomask_lstm(W,dataall  )
% gradient threshold for bptt need done   ,inLL,right
global   mzeros convert in_size gate_size out_size share_size usegpu...
    share_size2  in ingate cellstate cells outgate globalData    ...
    node_outgateInit cellinInit node_cellbiasInit delta_outInit
if nargin==1
    data=globalData;
else
    data=dataall;
end
if usegpu
    fun=@sigmoidnGpu;
    delta_fun=@delta_sigmoidnGpu;
    activation=@activationGpu;
    deactivation=@deactivationGpu;
else
    fun=@sigmoidnCpu;
    delta_fun=@delta_sigmoidnCpu;
    activation=@activationCpu;
    deactivation=@deactivationCpu;
end

actNum1=convert(1);
actNum2=2*actNum1;
numsamples=size(data,1) ;

dw= zeros(1 ,2*share_size2 +share_size2*numMmcell + (gate_size*numMmcell+1)*out_size);
[ Wingate,Wcell , Woutgate, Wout]=unpack(W);

[dwingate,dwcell,dwoutgate,dwout] = unpack2(dw);
dwingate=convert(dwingate);
dwcell=convert(dwcell);
dwoutgate=convert(dwoutgate);
dwout=convert(dwout);

right=zeros(numsamples,1,'int32');
inLL = 0;
inerr = zeros( numsamples,out_size);

timespan = size( data  , 3 );
node_tmpindex=cell(1,timespan);
node_tmpindex2=cell(1,timespan);
node_tmpindex3=cell(1,timespan);

node_outgate= node_outgateInit;
cellin=cellinInit;
node_cellbias=node_cellbiasInit;
delta_out=delta_outInit;
cellstatus= cellstatusInit;

node_ingate = node_outgate;
node_cell = cellin;
Y_cellout = cellin;
delta_outgate=node_outgate;

errorstate=cellin;
delta_cellin=cellin;
delta_ingate=node_outgate;

Wingate_in=convert( Wingate(in,:) );
Wingate_ingate= convert( Wingate(ingate,:) ); 
Wingate_cellstate=convert( Wingate(cellstate,:) );
Wingate_cell=convert( Wingate(cells,:) );
Wingate_outgate=convert( Wingate(outgate,:) );

% to cellin
Wcell_in=convert( Wcell(in,:) ) ;
Wcell_ingate=convert( Wcell(ingate,:) );
Wcell_cell=convert( Wcell(cells,:) );
Wcell_outgate=convert( Wcell(outgate,:) );

% to outgate
Woutgate_in=convert( Woutgate(in,:) );
Woutgate_ingate=convert( Woutgate(ingate,:) );
Woutgate_cellstate=convert( Woutgate(cellstate,:) ); 
Woutgate_cell = convert( Woutgate(cells,:) );
Woutgate_outgate=convert( Woutgate(outgate,:) );

t=2;
while t<=timespan
    
    output = data(:,1:out_size,t ) ;
    
    % forward pass   
    node_in = data(:,1:in_size,t-1);
    node_cellbias{t } = data(:,in_size+1,t-1); 
    
    % to ingate
    tmpp=node_in*Wingate_in + node_outgate{t-1}*Wingate_outgate +...
        cellstatus{t-1} * Wingate_cellstate + node_cell{t-1}*Wingate_cell +  node_ingate{t-1} * Wingate_ingate;
    node_ingate{t}=fun( tmpp ,signum);   
    
    tmpp=node_in*Wcell_in +  node_ingate{t-1}  * Wcell_ingate  +...
        + node_cell{t-1}*Wcell_cell +node_outgate{t-1} * Wcell_outgate ;
    cellin{t} = activation( tmpp,actNum2 ) ;
    
    cellstatus{t}  =  cellstatus{t-1}  +    cellin{t }  .* repmat(node_ingate{t},1,numMmcell )  ;
    
    Y_cellout{t}= activation( cellstatus{t } ,actNum1 ) ; 
    
    tmpp=node_in*Woutgate_in +   node_outgate{t-1} *Woutgate_outgate +...
        cellstatus{t}  * Woutgate_cellstate + node_cell{t-1}*Woutgate_cell +  node_ingate{t-1} * Woutgate_ingate;
    node_outgate{t }  = fun(tmpp  ,signum); 
    
    node_cell{t }  = repmat(node_outgate{t},1,numMmcell )   .* Y_cellout{t }  ;
    
    node_tmpindex{t } = [ node_in  node_ingate{t-1} cellstatus{t-1} node_cell{t-1} node_outgate{t-1} ];
    node_tmpindex2{t} = [ node_in  node_ingate{t-1} cellstatus{t} node_cell{t-1} node_outgate{t-1} ];
    node_tmpindex3{t } = [ node_in  node_ingate{t-1}  node_cell{t-1} node_outgate{t-1} ];

    node_out  = fun(  [ node_cell{t}     node_cellbias{t}   ] * Wout    ,signum ) ;
    
    delta_out{t} =  ( - output + node_out  )  .* delta_fun(node_out,signum);
    
    inerr = inerr +     (  (output  - node_out  )).^2    ;
    %       right = right +   rightfun(masko,output,node_out) ;
    t=t+1;
end
t=t-1;
% just  cell
tmp_outgate=repmat(node_outgate{t},1,numMmcell);
tmp_ingate=repmat(node_ingate{t},1,numMmcell);
errorcell = delta_out{t} * Wout(1:end-1,:)';  

% just cell to outgate 
delta_outgate{t} =  squeezing(delta_fun( tmp_outgate,signum) .* errorcell  .* Y_cellout{t})  ;  %  .* nodenew_outgate.* ( 1 - nodenew_outgate  )  ;
% peephole
errorstate{t} = errorcell .* tmp_outgate .* deactivation(Y_cellout{t},actNum1)+...
    delta_outgate{t} * Woutgate_cellstate' ;
delta_cellin{t} =tmp_ingate .* errorstate{t}.* deactivation(cellin{t},actNum2);
delta_ingate{t} =  squeezing(cellin{t} .* errorstate{t} .* delta_fun(tmp_ingate,signum)); 
for t = timespan-1:-1:2
    % just  cell
    tmp_outgate=repmat(node_outgate{t},1,numMmcell);
    tmp_ingate=repmat(node_ingate{t},1,numMmcell);
    errorcell = delta_out{t } * Wout(1:end-1,:)' + delta_outgate{t+1} * Woutgate_cell' +...
        delta_cellin{t+1} * Wcell_cell' + delta_ingate{t+1} * Wingate_cell'; % W( out , %cell);
    
    % just cell to outgate 
    delta_outgate{t} = delta_fun(  node_outgate{t},signum )  .* ( squeezing(errorcell  .* Y_cellout{t})  +...
        delta_ingate{t+1} * Wingate_outgate'+ delta_cellin{t+1} * Wcell_outgate'+...
        delta_outgate{t+1} *Woutgate_outgate') ;  %  .* nodenew_outgate.* ( 1 - nodenew_outgate  )  ;
    % peephole
    errorstate{t} = errorcell .* tmp_outgate .* deactivation( Y_cellout{t} ,actNum1 )  + ...
        errorstate{t+1} + delta_ingate{t+1}* Wingate_cellstate' +...
        delta_outgate{t} * Woutgate_cellstate' ;
    
    delta_cellin{t} = tmp_ingate .* deactivation( cellin{t } ,actNum2) .* errorstate{t} ;
    
    delta_ingate{t} = delta_fun( node_ingate{t} ,signum).* ( squeezing(cellin{t} .* errorstate{t})  +...
        + delta_ingate{t+1} * Wingate_ingate' +delta_cellin{t+1} * Wcell_ingate' + ...
        delta_outgate{t+1} * Woutgate_ingate' );
end

for t = 2:timespan
    dwout = dwout + [node_cell{t} node_cellbias{t} ]' *  delta_out{t} ;
    dwoutgate =dwoutgate + node_tmpindex2{t}' * delta_outgate{t} ;
    dwcell=dwcell+ node_tmpindex3{t}'*delta_cellin{t};
    dwingate = dwingate + node_tmpindex{t}'  * delta_ingate{t}   ;
end

inerr = gather(  1/2*    sum(    inerr)   /numsamples)  ;%  1/2*  for gradient checking
%right=gather(sum(right));

dw=pack2(dwingate,dwcell ,dwoutgate,dwout);
dw = gather(dw / numsamples );

    function [Wingate,Wcell ,Woutgate,Wout] = unpack(W)
        Wingate= reshape( W( 1:share_size2 )   , share_size ,gate_size );
        Wcell  = reshape( W( share_size2 +1 :   share_size2 *(1+numMmcell) ),  share_size, numMmcell*gate_size);
        Woutgate = reshape( W( (1+numMmcell) * share_size2 +1 : (2+numMmcell)* share_size2  ), share_size , gate_size);
        Wout = reshape( W( (2+numMmcell) * share_size2 +1 : end ) ,gate_size*numMmcell+1 ,  out_size);
    end
    function [Wingate,Wcell ,Woutgate,Wout] = unpack2(W)
        Wingate= reshape( W( 1:share_size2 )   , share_size ,gate_size );
        % Wcell  = reshape( W( share_size2 +1 : 2* share_size2  ),  share_size,gate_size);
        Wcell  = reshape( W( share_size2 +1 :   share_size2 *(1+numMmcell) ),  share_size, numMmcell*gate_size);
        %   share_size = in_size + gate_size * (2+2*problem.numMmcell) ;
        Wcell =  Wcell([1:in_size+gate_size (in_size+gate_size+gate_size*numMmcell+1):end],:) ;
        Woutgate = reshape( W( (1+numMmcell) * share_size2 +1 : (2+numMmcell)* share_size2  ), share_size , gate_size);
        Wout = reshape( W( (2+numMmcell) * share_size2 +1 : end ) ,gate_size*numMmcell+1 ,  out_size);
    end
    function [W]=pack2(Wingate,Wcell , Woutgate,Wout)
        tmp=mzeros(share_size,gate_size*numMmcell);
        tmp([1:in_size+gate_size (in_size+gate_size+gate_size*numMmcell+1):end],:)=Wcell;
        Wcell=tmp;
        W = [Wingate(:);Wcell(:) ;Woutgate(:);Wout(:)];
    end


    function y=sigmoidnGpu(x,num)
        y=arrayfun(@(x,num)1./(1+exp(- num*x)),x,num);
    end
    function y=delta_sigmoidnGpu(x,num)
        y=arrayfun(@(x,num)num*x.*(1-x),x,num);
    end
    function y=sigmoidnCpu(x,num)
        y=1./(1+exp(- num*x));
    end
    function y=delta_sigmoidnCpu(x,num)
        y=  num*x.*(1-x);
    end
    function y =  activationCpu(x,num)
        y=num*2./(1+exp(-x))-num;
    end
    function y =  deactivationCpu(x,num)
        y=0.5/num*(num+x).*(num-x);
    end
    function y =  activationGpu(x,num)
        y= arrayfun(@(x,num)num*2./(1+exp(-x))-num,x,num);
    end
    function y =  deactivationGpu(x,num)
        y=arrayfun(@(x,num)0.5/num*(num+x).*(num-x),x,num);
    end
    function y = squeezing(x)
        y=zeros(size(x,1),gate_size);
        for i = 1:numMmcell
            y = y + x(:,1+(i-1)*gate_size: i*gate_size);
        end
        %         x=mat2cell(x,size(x,1),gate_size*ones(1,numMmcell));
        %
        %         for i=2:numMmcell
        %             x{1}=x{1}+x{i};
        %         end
        %         y=x{1};
        %    y= cell2mat(cellfun(@plus  ,x, 'UniformOutput',false));
    end

end









