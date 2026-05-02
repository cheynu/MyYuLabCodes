medfiles = arrayfun(@(x)x.name,dir('*Subject*.txt'),'UniformOutput',false);
for i=1:length(medfiles)
    med = medfiles{i};
    dateraw = extractBefore(med,'_Subject');
    if ~isempty(dateraw)
        date = datetime(dateraw,'InputFormat','yyyy-MM-dd_HH''h''mm''m');
        datechar = char(date,'yyyyMMdd');
        [~,~] = mkdir(datechar);
        movefile(med,datechar);
    end
end