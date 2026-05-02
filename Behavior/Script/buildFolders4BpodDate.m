bpodfiles = arrayfun(@(x)x.name,dir('*DSRT*.mat'),'UniformOutput',false);
if isempty(bpodfiles)
    bpodfiles = arrayfun(@(x)x.name,dir('*SRTL*.mat'),'UniformOutput',false);
end
if isempty(bpodfiles)
    bpodfiles = arrayfun(@(x)x.name,dir('*LeverPressVI*.mat'),'UniformOutput',false);
end
for i=1:length(bpodfiles)
    bpod = bpodfiles{i};
    dateraw = extractBefore(bpod,'.mat');
    if ~isempty(dateraw)
        dateraw = dateraw(end-14:end); % the end is the reserved format: yyyyMMdd_HHmmss
        date = datetime(dateraw,'InputFormat','yyyyMMdd_HHmmss');
        datechar = char(date,'yyyyMMdd');
        [~,~] = mkdir(datechar);
        movefile(bpod,datechar);
    end
end
