function out = read_tiny_big_metadata(words_in,ind,fields)

%%% Routine to read in metadata for tiny images from giant binary file
%holding all metdata.

% valid field names:
% 1. keyword
% 2. filename
% 3. width
% 4. height
% 5. colors
% 6. date
% 7. engine
% 8. thumb_url
% 9. source_url
% 10. page
% 11. ind_page
% 12. ind_engine
% 13. ind_overall
% 14. label (1 = correct, 0 = incorrect, -1 = unlabelled)

%%% There are two modes of operation:
%
% 1. raw indexing mode
% --------------------
% Inputs:
% 1. words_in - 1 x nImages vector, each element being an integer
% in the range 1 to 73,777,893 (or whatever the total number of images in the dataset is).
% 2.  ind - 1 x nFields cell array holding requested fields (see
% list above) [optional - if ommitted, all fields will be returned].
% Outputs:
% 1. out - 1 x nImages structure holding the fields requested

% e.g. out = read_tiny_big_metadata([1:10],{'filename' 'label'});

% ++++++++++++++++++++++++++++++++++++++++++++++++++++
%
% 2. word based indexing.
% -----------------------
% Inputs:
% 1. word_in - 1 x nWords cell array, each entry holding one noun
% 2. ind - 1 x nWords cell array, each holding indices of images
% for the corresponding noun
% 3.  fields - 1 x nFields cell array holding requested fields (see
% list above)
% Outputs:
% 1. out - 1 x nImages structure holding the fields requested

% e.g. out = read_tiny_big_metadata('aardvark',[1:10],{'filename' 'label'});

% Requires: read_tiny_metadata_big_core.mex file

%%%% Hints regarding operation:
% The access time per image drops as the total number of images to be
% gathered increases. e.g. for 500,000 images load time is
% 1ms/image. For 100,000 images it is 2ms/image. So try and pass in big
% blocks of indices.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET PATHS BELOW TO tiny_images.bin AND tiny_index.mat
  
% path to giant binary file 
binary_fname = '/mit/tiny/data/tiny_metadata.bin';
% indexing info .mat file
binary_data_fname = '/mit/tiny/data/tiny_index.mat';

% END 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


TOTAL_NUM_IMGS = 79302017;

field_names = {'keyword' 'filename' 'width' 'height' 'colors' 'date' ...
    'engine' 'thumb_url' 'source_url' 'page' 'ind_page' ...
    'ind_engine' 'ind_overall' 'label'};

% if field actually a number
numeric_flag = [0 0 1 1 1 0 0 0 0 1 1 1 1 1];

if (nargin==1)
    RAW_INDEX_MODE = 1;
    ind = field_names;
elseif (nargin==2)
    RAW_INDEX_MODE = 1;
    if ~iscell(ind)
        ind = {ind};
    end
else % full 3 inputs
    RAW_INDEX_MODE = 0;

    if ~iscell(ind)
        % convert to cell arrays
        words_in = {words_in};
        ind = {ind};
    end

    if ~iscell(fields)
        fields = {fields};
    end

    nWords = length(words_in);

end



if RAW_INDEX_MODE

    %% just go and call binary with raw indices

    %% convert field names into numbers
    field_ind = [];
    for a=1:length(ind)
        field_ind = [ field_ind , strmatch(ind{a},field_names) ];
    end

    if isempty(field_ind)
        error('No valid field names');
    else
        nFields = length(field_ind);
    end

    %% check that all indices are >0 and <TOTAL_NUM_IMGS
    if ((sum(words_in<1)==0) & (sum(words_in>TOTAL_NUM_IMGS)==0))

        % now sort for speed
        [sorted_words,sort_ind] = sort(words_in);

        %% use MEX for sppedy reading in
        out = read_tiny_metadata_big_core(binary_fname, uint64(sorted_words), uint32(field_ind));
    else
        error('indices <0 or greater than total number of images');
    end

else % words_in and indices passed in

    %% convert field names into numbers
    field_ind = [];
    for a=1:length(fields)
        field_ind = [ field_ind , strmatch(fields{a},field_names) ];
    end

    if isempty(field_ind)
        error('No valid field names');
    else
        nFields = length(field_ind);
    end

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

        out = read_tiny_metadata_big_core( binary_fname, uint64(sorted_offsets), uint32(field_ind));

    end
end


% convert to string and trim whitespace
for a=1:nFields
    if numeric_flag(field_ind(a))
        tmp_out = int16(str2num(char(out{a}')));

        %%% hack workaround due to 'co' and 'in' problem
        if (field_ind(a)==14) & isempty(tmp_out)
            out{a}(find(out{a}(:)==99)) = 49;
            out{a}(find(out{a}(:)==105)) = 48;
            out{a}(find(out{a}(:)==110)) = 32;
            out{a}(find(out{a}(:)==111)) = 32;
            tmp_out = int16(fast_str2num(char(out{a}')));
        end

        out{a} = tmp_out;

    else
        out{a} = cellstr(char(out{a}'));
    end
    % sort back
    out{a}(sort_ind,:) = out{a};
end

% put into cell array
out = cell2struct(out,field_names(field_ind),2);


