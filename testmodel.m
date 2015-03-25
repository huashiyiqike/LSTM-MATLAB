function [inerr,dw,inLL,right ]=testmodel(W,dataall,maskall,problem )
% gradient threshold for bptt need done   ,inLL,right
global  mones mzeros convert in_size gate_size out_size share_size numMmcell usegpu...
    share_size2  in ingate cellstate cells outgate globalData  globalMask  ...
   signum     
if nargin==1
    data=globalData;
    mask=globalMask;
else
    data=dataall;
    mask=maskall;
end
signum=3;
switch problem.name
    case 'tempor'
        rightfun=@judge_tempor;
    case 'xor'
        rightfun=@judge_xor;
    otherwise
        rightfun=@judge_add;
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
 
timespan = size( data  , 3 );

node_outgate=cell(1,problem.T);
cellin=node_outgate;
node_cellbias=node_outgate;
delta_out= node_outgate;
cellstatus=node_outgate;
for i=1:problem.Ttest
   node_outgate{i}=0.5*mones(problem.numtest,gate_size);
   cellin{i}=mzeros(problem.numtest,problem.numMmcell*gate_size);
   node_cellbias{i}=mones(problem.numtest,1);
   delta_out{i}=mzeros(problem.numtest,out_size);
    cellstatus{i}=mzeros(problem.numtest,problem.numMmcell*gate_size);
end

node_ingate = node_outgate;
node_cell = cellin;
Y_cellout = cellin;
 
%node_cellbias =  mones( numsamples , 1 , timespan  );

Wingate_in=convert( Wingate(in,:) );%1:in_size,:);
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

right=zeros(problem.numtest,1,'int32');
inLL = 0;
inerr = zeros( problem.numtest,out_size);

t=2;
while t<=timespan
    
    output = data(:,1:out_size,t ) ;
    if ~isempty(mask)  
        masko=mask( : , 1 , t  ) ;
    elseif isempty(mask) || masko==0
        masko=1;
    end
    
    
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
    
    % Y_cellout is H[u][v]
    Y_cellout{t}= activation( cellstatus{t } ,actNum1 ) ; % H in the original
    
    tmpp=node_in*Woutgate_in +   node_outgate{t-1} *Woutgate_outgate +...
        cellstatus{t}  * Woutgate_cellstate + node_cell{t-1}*Woutgate_cell +  node_ingate{t-1} * Woutgate_ingate;
    node_outgate{t }  = fun(tmpp  ,signum); %node_cell*Woutgate_cellstate +  node_ingate * Woutgate_ingate );
    
    node_cell{t }  = repmat(node_outgate{t},1,numMmcell )   .* Y_cellout{t }  ;
    
     if any(masko)

        node_out  = fun(  [ node_cell{t}     node_cellbias{t}   ] * Wout    ,signum ) ;
        
        delta_out{t} = masko .* ( - output + node_out  )  .* delta_fun(node_out,signum); 
        inerr = inerr +     ( masko .* (output  - node_out  )).^2    ;

        right = right +   rightfun(masko,output,node_out) ;
    end
    t=t+1;
end

inerr =  gather(1/2*  double( sum(sum(inerr)) /numsamples ) );%  1/2*  for gradient checking
right=gather(sum(right));

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
        Wcell  = reshape( W( share_size2 +1 :   share_size2 *(1+numMmcell) ),  share_size, numMmcell*gate_size);
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
        x=mat2cell(x,size(x,1),gate_size*ones(1,numMmcell));
        %  y=zeros(size(x,1),gate_size);
        %         for i = 1:numMmcell
        %             y = y + x(:,1+(i-1)*gate_size: i*gate_size);
        %         end
        for i=2:numMmcell
            x{1}=x{1}+x{i};
        end
        y=x{1};
   end

    function y=judge_tempor(masko,output,node_out)
        y=int32(   sum(             masko  .*  convert(   double(  abs(output-node_out)<0.3   )      )        ,2 )==3           ) ;
    end
    function y=judge_add(masko,output,node_out)
        y= int32(  masko .*convert( abs(output-node_out)<0.04) );
    end
function y=judge_xor(masko,output,node_out)
        y= int32(  masko .*convert( abs(output-node_out)<0.3) );
    end
end









