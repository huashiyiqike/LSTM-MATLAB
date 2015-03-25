% setup_paths() sets up paths for the matlabserver code to include subdirectories, etc.
% This file is sourced by the serverInit() and slaveInit() functions.  You can add your
% own paths here if you like to ensure that they're added to the server and slaves.
%
% The returned variable 'rootpath' is the path of the setup_paths.m file
% (i.e., the matlabserver/ directory) which can be used to reference other
% internal paths by the caller.
function rootpath = setup_paths()
p=which('setup_paths');
i=strfind(p, 'setup_paths.m');

if (isempty(i))
  error('Couldn''t determine path of setup_paths.m');
end

p=p(1:i-1);
addpath(p); % add root path in case cwd changes.
 

rootpath=p;
