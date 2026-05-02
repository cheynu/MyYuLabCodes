function BMTPerfWait

% plot performance use BpodMEDTable
% for wait stage

BMT = readtable(dir('BpodMEDTable*.csv').name);
BMT.Date = cellstr(datestr(BMT.Date, "yyyymmdd"));
DATE = sort(unique(BMT.Date));

PerfTable = zeros(length(DATE), 4);  % 1 - correct; 2 - premature; 3 - late; 4 - dark.
RTTable = zeros(length(DATE), 2); % 1 - mean RT; 2 - sem.

for i = 1:length(DATE)

    curDate = BMT(strcmp(BMT.Date, DATE{i}), :);
    CorTrials = curDate(strcmp(curDate.Performance, {'Correct'}), :);
    PreTrials = curDate(strcmp(curDate.Performance, {'Premature'}), :);
    LateTrials = curDate(strcmp(curDate.Performance, {'Late'}), :);
    DarkTrials = curDate(strcmp(curDate.Performance, {'Dark'}), :);

    PerfTable(i, 1) = height(CorTrials)/(height(CorTrials)+height(PreTrials)+height(LateTrials));
    PerfTable(i, 2) = height(PreTrials)/(height(CorTrials)+height(PreTrials)+height(LateTrials));
    PerfTable(i, 3) = height(LateTrials)/(height(CorTrials)+height(PreTrials)+height(LateTrials));
    PerfTable(i, 4) = height(DarkTrials)/(height(CorTrials)+height(PreTrials)+height(LateTrials)+height(DarkTrials));

    curRT = CorTrials.tRelease - CorTrials.tTrigger;
    RTTable(i, 1) = mean(curRT);
    RTTable(i, 2) = std(curRT)/sqrt(length(curRT));

end

end