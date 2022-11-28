function b = getBehaviorData(tarPath)
    [filem,pathm] = uigetfile({'B_*.mat;bmixed*.mat','ProcessedData';...
        '*Subject*.txt;*DSRT*.mat','UnprocessedData'},...
        'Select behavior data',...
        tarPath,'MultiSelect','on');% med or bpod data
    if ~iscell(filem)
        [~,expName,dataext] = fileparts(filem);
    else
        [~,expName,dataext] = fileparts(filem{1});
    end
    switch dataext
        case '.txt' % Med unprocessed data
            b = track_training_progress_advanced(fullfile(pathm,filem));
        case '.mat'
            bData = load(fullfile(pathm,[expName,dataext]));
            if contains(expName,'B_') && ~isfield(bData,'bt') % Med processed data
                b = bData.b;
            else % Bpod data
                cfilem = cellstr(filem);
                btAll = cell(1,length(cfilem));
                if ~contains(expName,'B_') && ~contains(expName,'bmixed') % Bpod unprocessed data
                    for i=1:length(cfilem)
                        btAll{i} = DSRT_DataExtract_Block(fullfile(pathm,cfilem{i}),false);
                    end
                else % Bpod processed data
                    for i=1:length(cfilem)
                        bData = load(fullfile(pathm,cfilem{i}));
                        btAll{i} = bData.bt;
                    end
                end
                btAll = DSRT_DataMerge_Block(btAll,2); % if choose multiple files, merge it
                b = btAll{1};
            end
    end
end