function SRTSpikesPlotAll(SRTSpikesFnct)

% SRTSpikesFnct - SRTSpikes function to plot PSTH and raster plot
% example: SRTSpikesPlotAll('SRTSpikesLearningWait')


% RTarrayAll = dir('*.mat');
RTarrayAll = dir('*0*');
initPath = RTarrayAll(1).folder;

for i = 1:length(RTarrayAll)

    cd(RTarrayAll(i).name)
    load(['RTarrayAll_', RTarrayAll(i).name, '.mat']);
    if ~exist('PSTH', 'dir')
        mkdir('PSTH')
    end
    cd('PSTH');

    %     dataname = RTarrayAll(i).name;
    %     foldername = split(dataname, ["_", "."]);
    %     foldername = string(foldername{2});
    %     if ~exist(foldername, 'dir')
    %         mkdir(foldername);
    %     end
    %     cd(foldername);

    for j = 1:length(r.Units.SpikeNotes)
        cmd = [SRTSpikesFnct,'(r,', string(j), ');'];
        eval(join(cmd));
    end

    cd(initPath);

end

end