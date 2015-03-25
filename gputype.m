function [mones,mzeros,convert,useG]=gputype(usegpu)
switch usegpu
    case 'gpu_single'
        mones = @(varargin)  gpuArray(ones(varargin{:},'single'));
        mzeros = @(varargin) gpuArray(zeros(varargin{:},'single'));
        convert = @(varargin) gpuArray( single(varargin{:}) );
        useG=1;
    case 'gpu_double'
        mones = @(varargin)  gpuArray(ones(varargin{:},'double'));
        mzeros = @(varargin) gpuArray(zeros(varargin{:},'double'));
        convert = @(varargin) gpuArray( double(varargin{:}) );
        useG=1; 
    case 'cpu_single'
        mones = @(varargin)ones(varargin{:}, 'single');
        mzeros = @(varargin)zeros(varargin{:}, 'single');
        convert = @single;
        useG=0;
    case 'cpu_double'
        mones = @(varargin)ones(varargin{:}, 'double');
        mzeros = @(varargin)zeros(varargin{:}, 'double');
        convert = @(x)x;        
        useG=0;
end
end