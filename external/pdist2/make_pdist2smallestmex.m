function make_pdist2smallestmex()

%% Choose the source and function files
cd(fullfile(isetbioRootPath, 'external', 'pdist2'));
source = 'pdist2smallestmex.c';
output = '-output pdist2smallestmex';

%% Choose library files to include and link with.
LINC = '-L/usr/local/lib -L/usr/lib';
LIBS = '-lIlmImf -lz -lImath -lHalf -lIex -lIlmThread -lpthread';

%% Build the function.
mexCmd = sprintf('mex %s %s %s %s', LINC, LIBS, output, source);
fprintf('%s\n', mexCmd);
eval(mexCmd);