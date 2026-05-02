function packDataInDate(tarPath,dataType)
%   packDataInDate(tarPath,dataType) 
%   pack MED or BPOD data (.txt or .mat) into date folders
%   e.g., ~/Aqua/Learning/Aqua_DSRT_04_Wait1_20220714_174152.mat -->
%         ~/Aqua/Learning/20220714/Aqua_DSRT_04_Wait1_20220714_174152.mat
arguments
    tarPath {mustBeFolder} = pwd
    dataType {mustBeMember(dataType,{'bpod','med'})} = 'bpod'
end

switch lower(dataType)
    case {'bpod'}
        isBpod = true;
        files = arrayfun(@(x)x.name,dir(fullfile(tarPath,'*DSRT*.mat')),'UniformOutput',false);
    case{'med'}
        isBpod = false;
        files = arrayfun(@(x)x.name,dir(fullfile(tarPath,'*Subject*.txt')),'UniformOutput',false);
end

if ~isempty(files)
    for i=1:length(files)
        file = files{i};
        if isBpod
            dateraw = extractBefore(file,'.mat');
            dateraw = dateraw(end-14:end);
            date = datetime(dateraw,'InputFormat','yyyyMMdd_HHmmss');
        else
            dateraw = extractBefore(file,'_Subject');
            date = datetime(dateraw,'InputFormat','yyyy-MM-dd_HH''h''mm''m');
        end
        datechar = char(date,'yyyyMMdd');
        [~,~] = mkdir(tarPath,datechar);
        movefile(fullfile(tarPath,file),fullfile(tarPath,datechar));
    end
else
    warning('MED/BPOD files not found');
end

end

