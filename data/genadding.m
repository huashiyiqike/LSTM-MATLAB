function [data,mask,test,masktest]= genadding(problem)
global   mzeros convert
data=mzeros(problem.numsamples, 4 , ceil(problem.T*1.1));
mask=mzeros(problem.numsamples, 1 , ceil(problem.T*1.1));
test=mzeros(problem.numtest, 4 , ceil(problem.Ttest*1.1));
masktest=mzeros(problem.numtest, 1 , ceil(problem.Ttest*1.1));

T=fix(problem.T/1.1);
for i = 1 : problem.numsamples
 
    length = T+ fix(rand  * T / 10) ;
    mask(i,1,length)=1;

    data(i,3,1:length)=ones(1, length); %bias
    a=2*rand(1,length    ) - 1;
    data(i,1,1:length)=a;
    a=a';
    
    b=zeros(length,1);  %flag
    c=20*ones(length,1);
     
    data(i,4,1:length)=ones(1,length);%bias
 
    if T>10
        tmp1= ceil( rand * 10);
    else
        tmp1= ceil( rand * T/2);
    end
 
    data(i,2,tmp1)=1;
    b(tmp1,1)=1;
    
    tmp2=tmp1;
    while tmp2 == tmp1
        tmp2=  ceil(rand * T/2);
    end
 
    data(i,2,tmp2) = 1;
    b(tmp2,1)=1;
    
    if tmp2 ==1  || tmp1 ==1
        data(i,2,1)=0;
        b(1,1)=0;
    else
        data(i,2,1)=-1;
        b(1,1)=-1;
    end
    
    data(i,2,length-1)=-1;
    b(end,1)=-1;
    data(i,1,length) = 0.5+(data(i,1,tmp1)+data(i,1,tmp2))/4;
    c(end,1)= 0.5+(a(tmp1,1)+a(tmp2,1))/4;
    
end

for i =   size(data,3) :-1:1
    if max( max( data(:,:,i))) ~=0
        data=data(:,:,1:i);
        break
    end
end

for i = 1 : problem.numtest
 
    length = T+ fix(rand  * T / 10) ;
    masktest(i,1,length)=1;

    test(i,3,1:length)=ones(1, length); %bias
    test(i,1,1:length)=2*rand(1,length    ) - 1;
    
    test(i,4,1:length) = ones(1,length);%bias
 
    if T>10
        tmp1= ceil( rand * 10);
    else
        tmp1= ceil( rand * T/2);
    end
 
    test(i,2,tmp1)=1;
    
    tmp2=tmp1;
    while tmp2 == tmp1
        tmp2=  ceil(rand * T/2);
    end
 
    test(i,2,tmp2) = 1;
    
    if tmp2 ==1  || tmp1 ==1
        test(i,2,1)=0;
    else
        test(i,2,1)=-1;
    end
    
    test(i,2,length-1)=-1;
    test(i,1,length) = 0.5+(test(i,1,tmp1)+test(i,1,tmp2))/4;
end
for i =   size(test,3) :-1:1
    if max( max( test(:,:,i))) ~=0
        test=test(:,:,1:i);
        break
    end
end

tmp=test;
test=mzeros(size(test,1) ,  size(test,2) ,  size(test,3) +1  );
test(:,:,1)=tmp(:,:,1);
test(:,:,2:end)=tmp;

masktest=masktest(:,:,1:size(test,3));
tmp=masktest;
masktest=mzeros(size(masktest,1) ,  size(masktest,2) ,  size(masktest,3) +1  );
masktest(:,:,1)=tmp(:,:,1);
masktest(:,:,2:end)=tmp;

data=convert(data);
mask=convert(mask);
test=convert(test);
masktest=convert(masktest);


