function img = loadTinyImages(ndx, filename)
%
% Random access into the file of tiny images.
%
% It goes faster if ndx is a sorted list
%
% Input:
%    ndx = vector of indices
%    filename = full path and filename
% Output:
%    img = tiny images [32x32x3xlength(ndx)]

if nargin == 1
     filename = '/mit/tiny/data/tiny_images.bin';
%    filename = 'C:\atb\Databases\Tiny Images\tiny_images.bin';
end

% Images
sx = 32;
Nimages = length(ndx);
nbytesPerImage = sx*sx*3;
img = zeros([sx*sx*3 Nimages], 'uint8');

% Pointer
pointer = (ndx-1)*nbytesPerImage;
offset = pointer;
offset(2:end) = offset(2:end)-offset(1:end-1)-nbytesPerImage;

% Read data
[fid, message] = fopen(filename, 'r');
if fid == -1
    error(message);
end
frewind(fid)
for i = 1:Nimages
    fseek(fid, offset(i), 'cof');
    tmp = fread(fid, nbytesPerImage, 'uint8');
    img(:,i) = tmp;
end
fclose(fid);

img = reshape(img, [sx sx 3 Nimages]);
