function SeparateCortexStriatum(r, ifSplit, opts)

arguments
    r
    ifSplit = true % if it's false, set all units as DefaultType
    opts.DefaultType = 'Cortex'
end
defaultType = opts.DefaultType;
if isempty(ifSplit)
    ifSplit = true;
end

% load ./KilosortOutput.mat;
% load ./RTarray*.mat;
r.Units.SpikeNotes(:,5) = zeros(size(r.Units.SpikeNotes,1),1);
r.Units.SpikeNotesColumn5 = {'Cortex','Striatum','Others'};

ANM = r.BehaviorClass.Subject;
date =  r.BehaviorClass.Date;
%
if isfield(r,'ChanMap')
    chanMap = r.ChanMap;
elseif isfield(r.Units,'ChanMap')
    chanMap = r.Units.ChanMap;
end

ycoords = chanMap.ycoords;

unit_channels = r.Units.SpikeNotes(:,1);
unit_ycoords = ycoords(unit_channels);

unit_spike_width = zeros(1, length(r.Units.SpikeTimes));
unit_spike_height = zeros(2, length(r.Units.SpikeTimes));
PeaktoTroughRatio = zeros(1, length(r.Units.SpikeTimes));
mean_waveformAll =[];
for k = 1:length(r.Units.SpikeTimes)
    % compute the duration from the minimum to the next maximum
    mean_waveform = mean(r.Units.SpikeTimes(k).wave);
    [trough, idx_min] = min(mean_waveform);
    [peak, idx_max] = max(mean_waveform(idx_min+1:end));

    unit_spike_width(k) = idx_max./30000*1000;
    unit_spike_height(:,k) = [peak trough];
    PeaktoTroughRatio(k)   = abs(peak./trough);
    mean_waveformAll = [mean_waveformAll; mean_waveform];
end
%% select Striatum nerons
if ifSplit
    nplot = 7;
    brain ='Striatum';
    [idx_unit_Striatum, unit_Striatum_ycoords] = Spikes.selectBrainThreshold(unit_ycoords, unit_spike_width, PeaktoTroughRatio, unit_spike_height, mean_waveformAll,brain, nplot);
    
    brain ='Cortex';
    [idx_unit_Cortex, unit_Cortex_ycoords] = Spikes.selectBrainThreshold(unit_ycoords, unit_spike_width, PeaktoTroughRatio, unit_spike_height, mean_waveformAll,brain, nplot);
else
    nUnit = length(r.Units.SpikeNotes(:,5));
    switch defaultType
        case 'Cortex'
            idx_unit_Cortex = 1:nUnit;
            idx_unit_Striatum = [];
        case 'Striatum'
            idx_unit_Cortex = [];
            idx_unit_Striatum = 1:nUnit;
    end
end
r.Units.SpikeNotes(idx_unit_Striatum,5) = 2;
r.Units.SpikeNotes(idx_unit_Cortex,5) = 1;
r.Units.SpikeNotes(r.Units.SpikeNotes(:,5)==0,5) = 3;

fprintf('Striatum: %d units; Cortex: %d units; Others: %d units\n', length(idx_unit_Striatum), length(idx_unit_Cortex), length(find(r.Units.SpikeNotes(:,5)==3)));
%% 

% figure;
% fig2 = EasyPlot.figure();
% ax1 = EasyPlot.axes(fig2,...
%     'Width', 10,...
%     'Height', 5,...
%     'MarginBottom', 1,...
%     'MarginLeft', 1);

fig2 = figure('Units', 'centimeters', 'Position', [1, 1, 16, 7]);
ax1 = axes( 'Parent', fig2,'Units', 'centimeters', 'Position', [2, 1, 13, 5]);
cStriatum =  [0, 128, 0]./255;
cAxons = [128, 128, 128]./255;
cCortex = [255, 165, 0]./255;

% cMarker = ones(length(unit_ycoords),3).*100./255;
% cMarker(:,2) = cMarker(:,2).*r.Units.SpikeNotes(:,5);

cMarker = repmat(cAxons, length(unit_ycoords), 1);
cMarker(idx_unit_Striatum, :) = repmat(cStriatum, length(idx_unit_Striatum), 1);
cMarker(idx_unit_Cortex, :) = repmat(cCortex, length(idx_unit_Cortex), 1);
scatter(unit_ycoords, unit_spike_width, 15, cMarker,'filled');
xlim(ax1, [min(unit_ycoords)-500 max(unit_ycoords)+500])
xlabel(ax1, 'Y coord (um)');
ylabel(ax1, 'Trough-to-peak width (ms)');
try
text(2000,1, 'Striatum','Color',cMarker(find(r.Units.SpikeNotes(:,5)==2,1,"first"),:))
text(4000,1, 'Cortex','Color',cMarker(find(r.Units.SpikeNotes(:,5)==1,1,"first"),:))
end
saveas(fig2,['SeparateCortexStriatum_', ANM, date],'png')

%% 

r_name = ['RTarray_' r.BehaviorClass.Subject '_' r.BehaviorClass.Date '.mat'];
save(r_name, 'r', '-v7.3');

end