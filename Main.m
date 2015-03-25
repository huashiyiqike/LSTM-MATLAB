function []=Main(result,speed,options,problem,sgd)
global mones  mzeros convert  in_size gate_size numMmcell globalData globalMask usegpu...
    out_size share_size share_size2  in ingate cellstate cells outgate...
    node_outgateInit cellinInit node_cellbiasInit delta_outInit cellstatusInit signum

 signum = 3.5;
if problem.batchsize>problem.numsamples
    problem.batchsize=problem.numsamples;
end

[mones,mzeros,convert,usegpu]=gputype(speed.usegpu);
[data,mask,test,masktest ]=feval(['gen' problem.name],problem);
problem.numsamples=size(data,1);


[in_size,gate_size,out_size,share_size,share_size2,numMmcell,W,in,ingate,cellstate,cells,outgate,...
    node_outgateInit,cellinInit,node_cellbiasInit,delta_outInit,cellstatusInit ]=netInit(problem);
if problem.continualPredict
    Bpfunc=@batch_equal_nomask_lstm;
else
    Bpfunc=@batch_cell_lstm;
end

if speed.gradientchecking
        
    for i=1:fix(problem.numsamples/problem.batchsize)
        
        bashdata{i} =  data(  (i-1)*problem.batchsize + 1:i*problem.batchsize , : , :   );
        maskdata{i}= mask(  (i-1)*problem.batchsize + 1:i*problem.batchsize , : , :   );
    end
    
    globalData=bashdata{1};
    globalMask=maskdata{1};
    [ err,dw,inLL,right ]=Bpfunc(W);
    
    [numgrad]=computeNumericalGradient(Bpfunc,W);
    disp( [numgrad dw])
    diff = norm(numgrad-dw)/norm(numgrad+dw);
    disp(diff);
    fprintf('Norm of the difference between numerical and analytical gradient (should be < 1e-9)\n\n');
    return
end

if speed.usecluster
    serveroptions.slavecount=speed.numcluster;
    serveroptions.slavedir='/usr/local/anew-lstm';
    server=Server(serveroptions);
    
    markers = floor(linspace(1, size(data,2), server.slaveCount+1));
    markers(end) = size(data,2);
    markers(1) = 0;
    trainStarts = cell(1,server.slaveCount);
    trainEnds =cell(1,server.slaveCount);
    for i=1:server.slaveCount
        trainStarts{i} = markers(i)+1;
        trainEnds{i} = markers(i+1);
        fprintf('i = %d, trainStart = %d, trainEnd = %d\n', i, trainStarts{i}, trainEnds{i});
    end

    options.Method = 'lbfgs';
    
    for i=1:fix(problem.numsamples/problem.batchsize/server.slaveCount )
        bashdata{i} =  data(  (i-1)*problem.batchsize*server.slaveCount  + 1:...
            i*problem.batchsize*server.slaveCount  , : , :   );
        maskdata{i}= mask(  (i-1)*problem.batchsize*server.slaveCount + 1:...
            i*problem.batchsize*server.slaveCount  , : , :   );
    end
    clear data
 
    record=1;
    timer=tic;
    for epoch =1:1
        for i=1:fix(problem.numsamples/problem.batchsize/server.slaveCount )
            [Winit]=  server.rpc('clientLoadDataMinibatchNomask_ref',...
                trainStarts, trainEnds, problem.batchsize  ,...
                problem,speed,bashdata{i},maskdata{i},{1:server.slaveCount});
            if i==1&&epoch==1
                W=Winit{1};
            end
            for repeat = 1:32
                [W, cost] = minFunc( @server_batch_cell_lstm,W,options,server);
                if  toc(timer)>1
                    timearray{1}( record )= toc(timer)
                    [errorarray{1}(record),~,~,rightarray{1}(record) ]=testmodel(W,test,masktest ,problem);
                    timer=tic;
                    record=record+1;
                end
            end
        end
    end
    figure
    for method = 1:1
        plot(cumsum(timearray{method}), rightarray{method} , result.linspec{method}); hold on
    end
    legend('server  ' );
    xlabel('time(seconds)');
    ylabel('test obj');
    
    saveas(gcf,[ pwd '/picture/' num2str(problem.numsamples) '_' num2str(problem.Ttest) problem.name '.fig']);
    saveas(gcf,[ pwd '/picture/' num2str(problem.numsamples) '_' num2str(problem.Ttest)  problem.name '.eps'],'epsc');
    eps2pdf([pwd '/picture/' num2str(problem.numsamples) '_' num2str(problem.Ttest)  problem.name '.eps']);
      
    save('server.mat','timearray','errorarray');
    
elseif ~speed.usecluster
    
    
    for i=1:fix(problem.numsamples/problem.batchsize)
        
        bashdata{i} =  data(  (i-1)*problem.batchsize + 1:i*problem.batchsize , : , :   );
        maskdata{i}= mask(  (i-1)*problem.batchsize + 1:i*problem.batchsize , : , :   );
    end
    
    Winit=W;
    
   timer=tic;
   record=1;
    for i=1:fix(problem.numsamples/problem.batchsize)
        for inrepeat=1:20
            
            globalData =  bashdata{i};
            globalMask= maskdata{i};
            
            options.Method = 'lbfgs';
            
            [W, cost] = minFunc( Bpfunc,W,options);
            if toc(timer)>2
                
                timearray{1}( record  )= toc(timer);
                [errorarray{1}(record),~,~,rightarray{1}(record) ]=testmodel(W,test,masktest ,problem);
                disp([ 'lbfgs error '  num2str(errorarray{1}(record) )]  )
                record=record+1;
                timer=tic;
            end
        end
    end
 
        W=Winit;
        momentum=sgd.momentum;
        alpha=sgd.alpha;
        oldGradient=0;
    
        record =1;
        timer=tic;
        for repeat =1 :5
            for inner =1:50
    
                for  i=1:fix(problem.numsamples/problem.batchsize) 
    
                    globalData =  bashdata{i};
                    globalMask= maskdata{i};
    
                    [~,dw,~,~]=Bpfunc(W);     
                    oldGradient = alpha*dw + momentum* oldGradient;
                    W= W - alpha* oldGradient;
                end
                timearray{2}(record  )= toc(timer);
                [errorarray{2}(record),~,~, rightarray{2}(record) ]=testmodel(W,test,masktest ,problem);
                record=record+1;
                timer=tic;
            end
            disp([ 'sgd error '  num2str(errorarray{2}(record-1) )]  )
        end
        
    figure
    for method = 1:2
        plot(cumsum(timearray{method}), rightarray{method} , result.linespec{method}); hold on
    end
    legend('lbfgs','sgd');
    xlabel('time(seconds)');
    ylabel('test obj');
    
    figure
    for method = 1:2
        plot(cumsum(timearray{method}),errorarray{method} , result.linespec{method}); hold on
    end
    legend('lbfgs','sgd');
    xlabel('time(seconds)');
    ylabel('test e');
    
    if result.savepic
        saveas(gcf,[ pwd '/picture/' num2str(problem.numsamples) '_' num2str(problem.Ttest) problem.name '.fig']);
        saveas(gcf,[ pwd '/picture/' num2str(problem.numsamples) '_' num2str(problem.Ttest)  problem.name '.eps'],'epsc');
     %   eps2pdf([pwd '/picture/' num2str(problem.numsamples) '_' num2str(problem.Ttest)  problem.name '.eps']);
    end

end


end
