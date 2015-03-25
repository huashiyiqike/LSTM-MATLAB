function [imageFileName, keyword, correct, engine, ind_engine, image_ndx]=loadGroundTruth
% Load annotation file

fid = fopen('annotations.txt', 'r');
C = textscan(fid, '%s%s%d%s%d%d','delimiter',' ');
fclose(fid)
correct = C{3};
j = find(abs(correct)==1); 
imageFileName = C{1}(j);
keyword= C{2}(j);
correct = C{3}(j);
image_ndx = C{6}(j);
engine = C{4}(j);
ind_engine = C{5}(j);

