function im = read_tiny_gist_binary(words_in,ind)
%
%%% Routine to read in tiny images from giant binary file holding all
% 384-dim gist descriptors.
%
%%% There are two modes of operation:
%
% 1. raw indexing mode
% --------------------
% Inputs:
% 1. words_in - 1 x nImages vector, each element being an integer
% in the range 1 to 73,777,893 (or whatever the total number of images in the dataset is).
% Outputs:
% 1. im - 384 x nImages single data of Gist descriptors.
%
% ++++++++++++++++++++++++++++++++++++++++++++++++++++
%
% 2. word based indexing.
% -----------------------
% Inputs:
% 1. word_in - 1 x nWords cell array, each entry holding one noun
% 2. ind - 1 x nWords cell array, each holding indices of images
% for the corresponding noun
% Outputs:
% 1. im - 384 x nImages single data of Gist descriptors.
%
% Requires: read_tiny_binary_gist_core.mex file
%
%%%% Hints regarding operation:
% The access time per image drops as the total number of images to be
% gathered increases. e.g. for 500,000 images load time is
% 1ms/image. For 100,000 images it is 2ms/image. So try and pass in big
% blocks of indices.

% path to giant binary file (currently ~114Gb)
binary_fname = '/mit/tiny/data/tinygist80million.bin';
% indexing info .mat file
binary_data_fname = '/mit/tiny/data/tiny_index.mat';

% total # imgs
TOTAL_NUM_IMGS = 79302017;

if (nargin==1)
    RAW_INDEX_MODE = 1;
else
    RAW_INDEX_MODE = 0;
end


if (nargin==2)
    if iscell(ind)
        % do nothing
    else
        % convert to cell arrays
        words_in = {words_in};
        ind = {ind};
    end

    nWords = length(words_in);
end

if RAW_INDEX_MODE
    %% just go and call binary with raw indices
    %% check that all indices are >0 and <TOTAL_NUM_IMGS
    if ((sum(words_in<1)==0) & (sum(words_in>TOTAL_NUM_IMGS)==0))

        % now sort for speed
        [sorted_words,sort_ind] = sort(words_in);

        %% use MEX for sppedy reading in
        im = read_tiny_binary_gist_core(binary_fname, uint64(sorted_words));
        
        % sort back
        im(:,sort_ind) = im;
    else
        error('indices <0 or greater than total number of images');
    end

else % words_in and indices passed in

    % load up index data
    load(binary_data_fname);

    % compute hashes for all words_in
    hashes = compute_hash_function(words_in,hash_key);

    img_offsets = [];

    for a=1:nWords

        % find word using hash
        match_ind = find(hashes(a) == hash);

        if any(match_ind)
            % check all ind are >=1 and <=total number of images

            if ((sum(ind{a}<1)==0) & (sum(ind{a}>num_imgs(match_ind))==0))
                word_offset = offset(match_ind);
                img_offsets = [img_offsets , uint64(double(word_offset) + [ind{a}])];
            else
                error('indices <0 or greater than number per image');
            end
        else
           error('word not found');
        end

        % now sort for speed
        [sorted_offsets,sort_ind] = sort(img_offsets);

        im = read_tiny_binary_gist_core(binary_fname, uint64(sorted_offsets));

        % sort back
        im(:,sort_ind) = im;
    end
end

