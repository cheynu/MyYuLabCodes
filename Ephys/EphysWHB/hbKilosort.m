classdef hbKilosort < handle
    % Generate hbKilosort class with kilosort output results
    % Set coordinate map for current electrode
    % obj.plotSortResultAll
    % obj.checkSimilarity
    % Then obj.save and buildR
    properties
        SpikeTable
        ChanMap
        ParamsKilosort
    end
    
    methods (Static)
        function KilosortOutput = BuildFromDir(dir_name_kilosort, dir_name_spikeTable)
            if nargin<=0
                dir_name_kilosort = './kilosort2_5_output';
            end
            if nargin<=1
                dir_name_spikeTable = './';
            end
            chanMap = load(fullfile(dir_name_kilosort,'chanMap.mat'));
            load(fillfile(dir_name_kilosort,'ops.mat'),"ops");
            load(fullfile(dir_name_spikeTable,'spikeTable.mat'),"spikeTable");
            KilosortOutput = hbKilosort(spikeTable, chanMap, ops);
        end  
    end
    
    methods (Access=private)
        function sortSpikeTable(obj)
            obj.SpikeTable = sortrows(obj.SpikeTable,{'ch','group'});
        end        
    end

    methods
        function obj = hbKilosort(spikeTable, chanMap, ops)
            obj.SpikeTable = spikeTable;
            obj.ChanMap = chanMap;
            obj.ParamsKilosort = ops;
        end

        function set.SpikeTable(obj, in)
            arguments
                obj
                in table
            end
            obj.SpikeTable = in;
        end
        
        function save(obj, savePath, saveName)
            arguments
                obj
                savePath = pwd
                saveName = "KClass"
            end
            kClass = obj;
            save(fullfile(savePath, saveName), 'kClass');
        end

        function setXtrodeMap(obj, options)
            arguments
                obj
                options.xtrode string{mustBeMember(options.xtrode, ["MWA", "Tetrode", "Silicon"])} = "Silicon"
                options.map = []
            end
            if ~isempty(options.map)
                if numel(options.map) == obj.ChanMap.Nchannels
                    obj.ChanMap.xtrodeMap = options.map;
                else
                    error("Please check 'Map' element number")
                end
            else
                switch options.xtrode
                    case "MWA"  % 1 channel per xtrode, 8 ch per row
                        xmap = obj.ChanMap.chanMap;
                        n = double(obj.ChanMap.Nchannels/8);
                        xcoor = ones(1,n).*(1:8)'*size(obj.SpikeTable.waveforms_mean{1,1},2);
                        ycoor = (1:n).*ones(1,8)'*400;
                    case "Tetrode"  % 4 channels per xtrode and 4 ch per row
                        xmap = zeros(obj.ChanMap.Nchannels, 1);
                        n = double(obj.ChanMap.Nchannels/4);
                        for i = 1:obj.ChanMap.Nchannels
                            if ismember(mod(i,8), [1 3 5 7])
                                xmap(i) = floor((double(i)-1)/8)*2+1;
                            else
                                xmap(i) = floor((double(i)-1)/8)*2+2;
                            end
                        end
                        xcoor = ones(1,n/2).*[1 1 2 2 3 3 4 4]'*size(obj.SpikeTable.waveforms_mean{1,1},2);
                        ycoor = xmap*400;
                    case "Silicon"  % 16 channels per shank, and 8 ch per row
                        n = double(obj.ChanMap.Nchannels/16);
                        imap = ones(1,16); imap2 = ones(1,8);
                        xmap = (1:n).*imap';
                        xcoor = ones(1,2*n).*(1:8)'*size(obj.SpikeTable.waveforms_mean{1,1},2);
                        ycoor = (1:2*n).*imap2'*400;
                end
                obj.ChanMap.xtrodeMap  = reshape(xmap,  [], obj.ChanMap.Nchannels);
                obj.ChanMap.xcoor2plot = reshape(xcoor, [], obj.ChanMap.Nchannels);
                obj.ChanMap.ycoor2plot = reshape(ycoor, [], obj.ChanMap.Nchannels);
            end
        end

        function rClass = buildR(obj, options)
            arguments
                obj
                options.Subject       string = "Doge"             % Subject's name
                options.Blocks        double = [1,2]              % #block of ephys data (datafile00#.nev)
                options.DIOVersion    string = "Version4"         % DIO_Events#(NEV)
                options.MEDProtocol   string = "2FPs"             % MED protocol name
                options.BpodProtocol  string = "MedOptoRecording" % Bpod protocol name
                options.Experimenter  string = "hbWang"
                options.DebugMode            = 0
            end
            Subject = options.Subject;
            Blocks = options.Blocks;

            %% Check spks
            units = {};
            k = 1;
            while k <= height(obj.SpikeTable)
                channel = obj.SpikeTable(k,:).ch{1};
                j = k+1;
                while j <= height(obj.SpikeTable) && obj.SpikeTable(j,:).ch{1} == channel
                    j = j+1;
                end
                idxNew = size(units, 1)+1;
                type = '';
                for i = k:j-1
                    if strcmp(obj.SpikeTable(i,:).group{1},'good')
                        type = [type, 's']; %#ok<*AGROW> 
                    else
                        type = [type, 'm'];
                    end
                end
                units{idxNew, 1} = channel;
                units{idxNew, 2} = type;
                units{idxNew, 3} = [];
                k = j;
            end

            %% Track and combine DIOEVENT from BR
            EventOutCombined = [];
            dBlockOnset = zeros(length(Blocks), 1);
            for iBlock = 1:length(Blocks)
                % open ‘datafile###.nev’, create “datafile###.mat”
                openNEV(char("datafile00"+Blocks(iBlock)+".nev"), 'report', 'read')
                load("datafile00"+Blocks(iBlock)+".mat", "NEV");
                switch options.DIOVersion
                    case "Version4"
                        EventOut = DIO_Events4(NEV); % create
                    case "Version5"
                        EventOut = DIO_Events5(NEV); % create
                        % % Poke signals are incorrect. Update poke from
                        % bpod.  10/4/2022, Jan 2024 noted
                        % EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                        % EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                end
                if iBlock == 1
                    RecordingOnset = EventOut.Meta.DateTimeRaw;
                else
                    idt = EventOut.Meta.DateTimeRaw - RecordingOnset;
                    dBlockOnset(iBlock) = idt(end)+idt(end-1)*1000+...
                        idt(end-2)*1000*60+idt(end-3)*1000*60*60+idt(end-4)*1000*60*60*24;  %
                end

                EventOut.Meta.Subject = Subject;
                EventOut.Meta.Experimenter = options.Experimenter;
                EventOut.Meta.Protocol = options.MEDProtocol;
                if isfield(EventOut, 'Subject')
                    EventOut = rmfield(EventOut, 'Subject');
                end
                if isfield(EventOut, 'Experimenter')
                    EventOut = rmfield(EventOut, 'Experimenter');
                end
                if iBlock == 1
                    EventOutCombined = EventOut;
                    EventOutCombined.EventsLabels = string(EventOutCombined.EventsLabels);
                    EventOutCombined = rmfield(EventOutCombined, 'TimeEvents');
                else
                    EventOutCombined.Meta(iBlock) = EventOut.Meta;
                    for k = 1:length(EventOutCombined.EventsLabels)
                        EventOutCombined.Onset{k}  = [EventOutCombined.Onset{k}; ...
                            EventOut.Onset{k}  + dBlockOnset(iBlock)];
                        EventOutCombined.Offset{k} = [EventOutCombined.Offset{k};...
                            EventOut.Offset{k} + dBlockOnset(iBlock)];
                    end
                end
            end


            if options.MEDProtocol == "AutoShaping"
                BpodFile = dir(Subject+"*.mat");
                BehaviorClass = BehaviorSRT(BpodFile.name);
                EventOutCombined = hbUpdateDIOAutoShaping(EventOutCombined, BehaviorClass);
            else
                %% Track Bpod data and align to BR
                BpodFile = dir(Subject+"*.mat");
                load(BpodFile.name, "SessionData");
                BpodEvents = TrackBpodBehavior(SessionData, options.BpodProtocol);
                disp('**** Aligning Bpod to BlackRock ****');
                EventOutCombined = hbAlignBpod2BR(EventOutCombined, BpodEvents, ...
                    options.BpodProtocol, options.DebugMode);
                
                %% Track MED data and align to BR
                MEDFile = dir('*Subject*.txt');
                % [bMED, BehaviorClass]= TrackMEDBehavior(MEDFile.name, options.MEDProtocol);
                [bMED, ~]= TrackMEDBehavior(MEDFile.name, options.MEDProtocol);
                BehaviorClass = BehaviorMED(MEDFile.name, BpodFile.name, options.MEDProtocol);
                disp('**** Aligning MED to BlackRock ****');
                if options.DebugMode
                    EventOutCombined = hbAlignMED2BRbyTrigger(EventOutCombined, bMED);
                end
                EventOutCombined = hbAlignMED2BR(EventOutCombined, bMED, options.MEDProtocol);
            end
            %% Construct R array with aligned behavior, spikes and LFP data
            % turn everything in minutes
            % single unit: 1; multiunit: 2
            r = struct;
            r.Meta = EventOutCombined.Meta;
            r.BehaviorClass = BehaviorClass;
            
            r.Behavior.Labels = ["FrameOn", "FrameOff", ...
                "LeverPress", "Trigger", "LeverRelease", ...
                "ValveOnset", "ValveOffset", "PokeOnset", "BadPokeOnset"];
            r.Behavior.LabelMarkers = 1:length(r.Behavior.Labels);
            
            r.Behavior.Outcome        = EventOutCombined.OutcomeEphys;
            r.Behavior.CorrectIndex   = find(r.Behavior.Outcome == "Correct");
            r.Behavior.PrematureIndex = find(r.Behavior.Outcome == "Premature");
            r.Behavior.LateIndex      = find(r.Behavior.Outcome == "Late");
            r.Behavior.DarkIndex      = find(r.Behavior.Outcome == "Dark");
            r.Behavior.Foreperiods    = EventOutCombined.FPEphys;
            r.Behavior.EventTimings   = [];
            r.Behavior.EventMarkers   = [];
            
            % add frame signal: 1 on, 2 off
            idxFrame = EventOutCombined.EventsLabels == 'Frame';
            EventOnset = EventOutCombined.Onset{idxFrame};
            EventOffset = EventOutCombined.Offset{idxFrame};
            EventMix = [EventOnset; EventOffset];
            idxEventMix = [ones(length(EventOnset), 1); ones(length(EventOffset), 1)*2];
            r.Behavior.EventTimings = [r.Behavior.EventTimings; EventMix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; idxEventMix];

            % add leverpress onset and offset signal: 3 and 5
            idxLeverPress = EventOutCombined.EventsLabels == "LeverPress";
            EventOnset  = EventOutCombined.Onset{idxLeverPress};
            EventOffset = EventOutCombined.Offset{idxLeverPress};
            EventMix = [EventOnset; EventOffset];
            idxEventMix = [ones(length(EventOnset), 1)*3; ones(length(EventOffset),1)*5];
            r.Behavior.EventTimings = [r.Behavior.EventTimings; EventMix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; idxEventMix];

            % add trigger stimulus signal: 4
            idxTrigger = EventOutCombined.EventsLabels == "Trigger";
            EventOnset = EventOutCombined.Onset{idxTrigger};
            EventMix = EventOnset;
            idxEventMix = ones(length(EventOnset), 1)*4;
            r.Behavior.EventTimings = [r.Behavior.EventTimings; EventMix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; idxEventMix];

            % add valve onset and offset signals: 6 and 7
            idxValve = EventOutCombined.EventsLabels == "Valve";
            EventOnset  = EventOutCombined.Onset{idxValve};
            EventOffset = EventOutCombined.Offset{idxValve};
            EventMix = [EventOnset; EventOffset];
            idxEventMix = [ones(length(EventOnset), 1)*6; ones(length(EventOffset), 1)*7];
            r.Behavior.EventTimings = [r.Behavior.EventTimings; EventMix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; idxEventMix];
            
            % plot Event times
            figure(1); clf(1, "reset");
            set(gcf, 'name', 'CombinedEvents', 'color', 'w', ...
                'unit', 'centimeters', 'position',[2 2 25 15], 'paperpositionmode', 'auto');
            ha11 = axes;
            set(ha11, 'nextplot', 'add', 'ylim', [0 10]);
            if ~isempty(EventOutCombined.Onset{idxLeverPress})
                plot(EventOutCombined.Onset{idxLeverPress}, 2, 'ko');
                text(EventOutCombined.Onset{idxLeverPress}(1), 2.5, 'Press');
                plot(EventOutCombined.Offset{idxLeverPress}, 6, 'bo');
                text(EventOutCombined.Offset{idxLeverPress}(1), 6.5, 'Release');
            end
            plot(EventOutCombined.Onset{idxTrigger}, 4, 'ro');
            text(EventOutCombined.Onset{idxTrigger}(1), 4.5, 'Tone');

            plot(EventOutCombined.Onset{idxValve}, 8, 'm^');
            text(EventOutCombined.Onset{idxValve}(1), 8.5, 'Valve');

            % add poke onset signals: 8
            idxPoke = EventOutCombined.EventsLabels == "Poke";
            EventOnset = EventOutCombined.Onset{idxPoke};
            EventMix = EventOnset;
            idxEventMix = ones(length(EventOnset), 1)*8;
            r.Behavior.EventTimings = [r.Behavior.EventTimings; EventMix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; idxEventMix];

            % add badpoke onset signals: 9
            idxBadPoke = EventOutCombined.EventsLabels == "BadPoke";
            if any(idxBadPoke)
                EventOnset = EventOutCombined.Onset{idxBadPoke};
            else
                EventOnset = [];
            end
            EventMix = EventOnset;
            idxEventMix = ones(length(EventOnset), 1)*9;
            r.Behavior.EventTimings = [r.Behavior.EventTimings; EventMix];
            r.Behavior.EventMarkers = [r.Behavior.EventMarkers; idxEventMix];

            % sort timing
            [r.Behavior.EventTimings, idxTiming] = sort(r.Behavior.EventTimings);
            r.Behavior.EventMarkers = r.Behavior.EventMarkers(idxTiming);

            %% plot behavior data
            close all;

            SumFig = figure(2); clf(2, "reset");
            set(gcf, 'name', 'Summary of current R array', 'color', 'w', ...
                'unit', 'centimeters', 'position', [2 2 30 20], 'paperpositionmode', 'auto' );
            ha21 = axes;
            set(ha21, 'units', 'centimeters', 'position', [2.5 12 27 6], ...
                'nextplot', 'add', 'fontsize', 8,...
                'xlim', [0 max(r.Behavior.EventTimings/(1000))],...
                'ytick', 1:length(r.Behavior.Labels), 'yticklabel', r.Behavior.Labels);
            plot(r.Behavior.EventTimings/(1000), r.Behavior.EventMarkers, 'o',...
                'color', 'k','markersize', 4, 'linewidth', 1.5)
            line([0 max(r.Behavior.EventTimings/(1000))],...
                [1:length(r.Behavior.Labels); 1:length(r.Behavior.Labels)], 'color', [0.8 0.8 0.8]);
            ha21.XAxis.Visible = 'off';

            r.Units.Channels   = 1:obj.ParamsKilosort.Nchan;
            if ~isfield(obj.ChanMap, "xtrodeMap")
                obj.setXtrodeMap();
            end
            r.Units.ChannelMap = obj.ChanMap;
            r.Units.Profile    = units;
            r.Units.Definition = {'channel_id cluster_id unit_type polytrode',...
                '1: single unit', '2: multi unit'};
            r.Units.SpikeNotes = [];

            for i = 1:size(units, 1)
                for k = 1:length(units{i, 2})
                    switch units{i, 2}(k)
                        case 'm'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                        case 's'
                            r.Units.SpikeNotes = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                    end
                end
            end

            SpkChs = unique(r.Units.SpikeNotes(:, 1));
            allColors = varycolor(length(SpkChs));

            ha22 = axes;
            set(ha22, 'units', 'centimeters', 'position', [2.5 1 27 10.5], ...
                'nextplot', 'add', 'fontsize', 8,...
                'xlim', get(ha21, 'xlim'), ...
                'ylim', [0 size(r.Units.SpikeNotes , 1)+0.1]);
            linkaxes([ha21, ha22], 'x');
            xlabel('Time (sec)', 'FontSize', 10, 'FontName', 'Arial');
            ylabel('# Units', 'FontSize', 10, 'FontName', 'Arial');

            ha0 = axes;
            set(ha0, 'units', 'centimeters', 'position', [1.5 18 27 0.5]); axis off;
            title("Summary of "+Subject+"-"+string(BehaviorClass.Date)+"-"+options.MEDProtocol, ...bMED.Metadata.Date
                "FontSize", 12, "FontWeight", "bold", "FontName", "Arial");

            % put spikes
            for i = 1:size(r.Units.SpikeNotes, 1)
                iChannel = r.Units.SpikeNotes(i, 1);  % channel id
                r.Units.SpikeTimes(i) = struct('timings', [], 'wave', [], 'wave_mean', [], 'spk_id', []);
                r.Units.SpikeTimes(i).timings   = round(obj.SpikeTable(i,:).spike_times_r{1});
                r.Units.SpikeTimes(i).wave      = obj.SpikeTable(i,:).waveforms{1};
                r.Units.SpikeTimes(i).wave_mean = obj.SpikeTable(i,:).waveforms_mean{1};
                r.Units.SpikeTimes(i).spk_id = 1:length(r.Units.SpikeTimes(i).timings);
                if length(r.Units.SpikeTimes(i).timings) >= 10000
                    prctRemove = 0.9;
                else
                    prctRemove = 1-1000/length(r.Units.SpikeTimes(i).timings);
                end

                if prctRemove > 0
                    idxRemove = randperm(length(r.Units.SpikeTimes(i).timings),...
                        round(length(r.Units.SpikeTimes(i).timings)*prctRemove));
                    r.Units.SpikeTimes(i).spk_id(idxRemove) = [];
                    r.Units.SpikeTimes(i).wave(idxRemove, :) = [];
                end

                x_plot = r.Units.SpikeTimes(i).timings/1000;
                y_plot =  i - 1 + 0.8*rand(1, length(x_plot));
                if ~isempty(x_plot)
                    plot(ha22, x_plot, y_plot, '.', ...
                        'color', allColors(SpkChs == iChannel, :), 'markersize', 4);
                end
            end
            set(ha22, 'xlim', [0 max(r.Behavior.EventTimings/(1000))]);

            tic
            rClass = hbRClass(r);
            rClass.save();
%             save(savename, 'r', '-v7.3');

            [~,~] = mkdir(pwd,"Fig");
            savename = fullfile(pwd,'Fig', ...
                "RTarrayAll_"+Subject+"_"+string(BehaviorClass.Date)+"_"+options.MEDProtocol);
            
            saveas(SumFig,savename,'fig');
            print(SumFig,'-dpng',savename);
            print(SumFig,'-depsc2',savename);
            toc

            disp('********************');
            disp('**** COME R! :) ****');
            disp('********************');
        end

        function Fig = plotSortResult(obj, inputID, options)
            arguments
                obj
                inputID
                options.inputType string {mustBeMember(options.inputType,  ...
                    ["Channel", "Unit"])} = "Channel"
                options.waveType string {mustBeMember(options.waveType, ...
                    ["Normal", "Heatmap", "MultiChannel"])} = "Heatmap"
            end
            switch options.inputType
                case "Channel" % Summary of target channel
                    if length(inputID) == 1
                        idxUnits = find(cell2mat(obj.SpikeTable.ch) == inputID);
                        allChannel = repmat(inputID, length(idxUnits));
                        allUnit = 1:length(idxUnits);
                        titleText = "Ch"+num2str(inputID)+" Units Sorting Results";
                    else
                        error("More than one channel selected, set 'inputType' as 'Unit' instead");
                    end
                case "Unit"
                    idxUnits = inputID;
                    allChannel = arrayfun(@(x) obj.SpikeTable.ch{x}, idxUnits);
                    allUnit = zeros(1, length(allChannel));
                    tempText = "|";
                    for i = 1:length(allChannel)
                        idx = find(cell2mat(obj.SpikeTable.ch) == allChannel(i));
                        allUnit(i) = find(idxUnits(i) == idx); % Unit id of this channel
                        tempText = tempText + "  Ch" + num2str(allChannel(i)) + "U" + num2str(allUnit(i)) ...
                            + " KC" + num2str(obj.SpikeTable.cluster_id(idxUnits(i))) + "  |";
                    end
                    if length(inputID) == 1
                        titleText = "Unit Sorting Results: " + tempText;
                    else
                        titleText = ["Sorting Results Comparison between"; tempText];
                    end
            end

            spkLength = size(obj.SpikeTable.waveforms_mean{idxUnits(1),:},2);
            nUnit = length(idxUnits);

            % Colors and colormaps
            allColor = tab10(nUnit); allColor2 = tab20(nUnit*2);
            bgColor  = Pastel1(9);
            for i = 1:nUnit
                myColormap{i} = customcolormap([0 1], [allColor(i,:); bgColor(6,:)]);
            end
            w = struct("Wave", 0.8, "MeanWave", 2, "ISI", 0.8);
            alpha = struct("spkRange", 0.2);
            fontSize = struct("Axes", 7, "Label", 9, "Title", 10);
            tickLen = [0.02 0.01];

            % Build map for axes
            xstart = 1.5; ystart = 1.5; xgap = 0.8; ygap = 0.8;
            axeSize1 = [3 3*0.8];
            fullWidth = axeSize1(1)*(nUnit+1)+xgap*(nUnit);
            axeSizeRast = [fullWidth*3/4 fullWidth/3];
            axeSizeHist = [fullWidth*1/4 fullWidth/3];

            xmap(1) = xstart; ymap(1) = ystart;
            ymap(2) = ymap(1) + ygap*2 + axeSizeRast(2);
            for i = 2:nUnit+1
                xmap(i) = xmap(i-1) + axeSize1(1) + xgap;
            end
            xmap(2:end) = xmap(2:end) + xgap;

            for i = 3:nUnit+2
                ymap(i) = ymap(i-1) + axeSize1(2) + ygap;
            end
            ymap(3:end) = ymap(3:end) + ygap;
            ymap = fliplr(ymap);

            xmap2 = [xstart, ...
                     xstart + xgap*1 + axeSizeRast(1), ...
                     xstart + xgap*2 + axeSizeRast(1) + axeSizeHist(1)];

            figSize = [xmap(end)+xgap+axeSize1(1) ymap(1)+ygap+axeSize1(2)+1];

            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'units', 'centimeters', 'color', 'w', 'position', [2 2 figSize], ...
                'paperpositionmode', 'auto');

            % Calculate
            nameUnit = cell(1, nUnit);
            wUnit2Plot    = cell(1, nUnit);
            meanWave2Plot = cell(1, nUnit);
            spkTime2Plot  = cell(1, nUnit);
            spkRange2Plot = cell(1, nUnit);
            for i = 1:nUnit
                if string(obj.SpikeTable.group{idxUnits(i)}) == "good"
                    unitType = "S";
                else
                    unitType = "M";
                end
                nameUnit{i} = "Ch"+num2str(allChannel(i))+"U"+num2str(allUnit(i)) ...
                    +" KC"+obj.SpikeTable.cluster_id(idxUnits(i))+" "+unitType;
                itUnit = obj.SpikeTable.spike_times_r{idxUnits(i),:};
                iwUnit = obj.SpikeTable.waveforms{idxUnits(i),:};

                if length(itUnit) > 1000
                    idx = randperm(length(itUnit), 1000);
                else
                    idx = 1:length(itUnit);
                end
                wUnit2Plot{i} = iwUnit(idx,:);
                wUnitAll{i} = iwUnit;
                meanWave2Plot{i} = mean(iwUnit);
                spkTime2Plot{i} = itUnit;

                ispkRange.Peak   = max(iwUnit, [], 2);
                ispkRange.Trough = min(iwUnit, [], 2);
                if abs(median(ispkRange.Peak)) > abs(median(ispkRange.Trough))
                    spkRange2Plot{i} = ispkRange.Peak;
                    idxSpk = [0.3 1.7];  % index of spike range (based on median peak/trough)
                else
                    spkRange2Plot{i} = ispkRange.Trough;
                    idxSpk = [1.7 0.3];
                end
                if i == 1
                    xLim.tRange   = [0 max(spkTime2Plot{i})];
                    yLim.spkRange = idxSpk*median(spkRange2Plot{i});
                    yLim.waveRange = 1.5*[median(ispkRange.Trough) median(ispkRange.Peak)];
                else
                    xLim.tRange   = [0 max([max(spkTime2Plot{i}) xLim.tRange(2)])];
                    yLim.spkRange = [min([idxSpk(1)*median(spkRange2Plot{i}) yLim.spkRange(1)]) ...
                        max([idxSpk(2)*median(spkRange2Plot{i}) yLim.spkRange(2)])];
                    yLim.waveRange = [min([1.5*median(ispkRange.Trough) yLim.waveRange(1)]) ...
                        max([1.5*median(ispkRange.Peak) yLim.waveRange(2)])];

                end

                % Autocorrelation
                temp = round(itUnit);
                tUnit2 = zeros(1, max(temp));
                tUnit2(temp) = 1;
                [corr, lags] = xcorr(tUnit2, 25);
                corr(lags==0) = 0;
    
                hacorr = axes;
                set(hacorr, 'Units', 'centimeters', 'Position', [xmap(1+i) ymap(1+nUnit) axeSize1], ...
                    'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                    'XLim', [-25 25], 'XTick', -40:20:40, 'XTickLabel', {}, ...
                    'YLim', [0 max([max(corr) 1])], 'YTick', [0 max([max(corr) 1])], ...
                    'FontSize', fontSize.Axes, 'FontName', 'Arial');
                bar1 = bar(lags, corr, 'hist');
                bar1.FaceColor = allColor2(2*i-1,:); bar1.FaceAlpha = 0.6; bar1.EdgeColor = 'None';
                set(hacorr, 'XTickLabel', string(-40:20:40));
                xlabel("Lag (ms)", "FontSize", fontSize.Label, "FontName", "Arial");

                % ISI of mixed units
                for j = 1:i
                    if j == i
                        ISI = diff(itUnit);
                        rISI = nnz(ISI < 3);
                        colorISI = allColor2(2*j-1,:);
                    else
                        jtUnit = obj.SpikeTable.spike_times_r{idxUnits(j),:};
                        ijtUnit = sort([itUnit jtUnit]);
                        ISI = diff(ijtUnit);
                        rISI = nnz(ISI < 3);
                        colorISI = mean([allColor2(2*i-1,:);allColor2(2*j-1,:)]);
                    end
                    ratioISI.("isi"+num2str(i)+num2str(j)) = 100*rISI/length(ISI);
                    ha.("isi"+num2str(i)+num2str(j)) = axes;
                    set(ha.("isi"+num2str(i)+num2str(j)), ...
                        'Units', 'centimeters', 'Position', [xmap(1+j) ymap(i) axeSize1], ...
                        'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                        'XLim', [0 50], 'XTick', [], ...
                        'FontSize', fontSize.Axes, 'FontName', 'Arial');
                    histogram(ha.("isi"+num2str(i)+num2str(j)), ISI, 0:1:50, ...
                        'FaceColor', colorISI, 'EdgeColor', 'none');
                    if j == i
                        title("Ch"+num2str(allChannel(i))+"U"+num2str(allUnit(i)), ...
                            "FontSize", fontSize.Label, "FontName", "Arial");
                    else
                        title("Ch"+num2str(allChannel(j))+"U"+num2str(allUnit(j))+ ...
                            " + Ch"+num2str(allChannel(i))+"U"+num2str(allUnit(i)), ...
                            "FontSize", fontSize.Label, "FontName", "Arial");
                    end
                    
                    if i == nUnit
                        set(ha.("isi"+num2str(i)+num2str(j)), 'XTick', 0:10:50);
                        xlabel("ISI (ms)", "FontSize", fontSize.Label, "FontName", "Arial");
                    end
                end

            end

            % Set ISI axes to same YLim, and add lines and texts
            yLimISI = [0 0];
            fname = string(fieldnames(ha));
            for k = 1:length(fname)
                temp = get(ha.(fname(k)), "YLim");
                yLimISI = [min([temp(1) yLimISI(1)]) max([temp(2) yLimISI(2)])];
            end
            for k = 1:length(fname)
                set(ha.(fname(k)), "YLim", yLimISI, "YTick", yLimISI);
                line(ha.(fname(k)), [3 3], yLimISI, 'Color', 'k', 'LineStyle', '--', 'LineWidth', w.ISI);
                text(ha.(fname(k)), 5, 0.9*yLimISI(2), num2str(ratioISI.(fname(k)), "%.2f")+"%", ...
                    "FontSize", fontSize.Label, "FontWeight", "bold", "FontName", "Arial");
            end

            for i = 1:nUnit
                hawave = axes;
                set(hawave, 'Units', 'centimeters', 'Position', [xmap(1) ymap(i) axeSize1], ...
                    'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                    'XLim', [1 spkLength], 'XTick', [], 'XTickLabel', {}, ...
                    'YLim', yLim.waveRange, ...
                    'FontSize', fontSize.Axes, 'FontName', 'Arial');
                switch options.waveType
                    case "Normal" % Spike waveform of each unit
                        plot(1:spkLength, wUnit2Plot{i}, ...
                            'Color', allColor2(2*i,:), 'LineStyle', '-', 'LineWidth', w.Wave);
                        plot(1:spkLength, mean(wUnit2Plot{i}), ...
                            'Color', allColor2(2*i-1,:), 'LineStyle', '-', 'LineWidth', w.MeanWave);

                    case {"Heatmap", "MultiChannel"} % Spike heatmap
                        yEdge.spkWave = yLim.waveRange(1):20:yLim.waveRange(2);
                        spkWaveCount = zeros(length(yEdge.spkWave)-1, spkLength);
                        for k = 1:spkLength
                            spkWaveCount(:,k) = histcounts(wUnitAll{i}(:,k), yEdge.spkWave);
                        end
                        imagesc(hawave, 1:spkLength, yLim.waveRange, spkWaveCount);
                        hawave.YDir = 'normal';
                        colormap(hawave, myColormap{i});
                end
            end

            % Spike mean waveform
            ha0 = axes;
            set(ha0, 'Units', 'centimeters', 'Position', [xmap(1)-xstart*0.8 ymap(1+nUnit)-ygap*1.5 axeSize1(1)+xgap*2 axeSize1(2)+ygap*2], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            switch options.waveType
                case {"Normal", "Heatmap"}
                    set(ha0, 'XLim', [1 spkLength], 'YLim', yLim.waveRange); axis off;
                    title("Mean Waveforms", "FontSize", fontSize.Label, "FontName", "Arial");
                    for i = 1:nUnit
                        plot(1:spkLength, meanWave2Plot{i}, 'Color', allColor(i,:), ...
                            'LineStyle', '-', 'LineWidth', w.MeanWave);
                    end
                case "MultiChannel"
                    axis off;
                    ha0.YDir = "reverse";

                    xc = obj.ChanMap.xcoor2plot;  % xc - x coordinates of each channel
                    yc = obj.ChanMap.ycoor2plot;  % yc - y coordinates of each channel

                    xtmap = obj.ChanMap.xtrodeMap;  % map of #tetrode or #shank
                    maxAmp = 0; wfAll = cell(nUnit, 1);
                    for i = 1:nUnit
                        ch = obj.SpikeTable(idxUnits(i), :).ch{1};
                        idxSameProbe = find(xtmap == xtmap(ch)); % channels in the same probe/tetrode
                        iwfAll = obj.SpikeTable(idxUnits(i),:).waveforms_mean{1};  % waveform in all channels
                        iwfAll = iwfAll(idxSameProbe, 17:end);  % left waveforms in the same probe, and 1:16 not that useful
                        wfAll{i}.wf = iwfAll;
                        wfAll{i}.xc = xc(idxSameProbe)';
                        wfAll{i}.yc = yc(idxSameProbe)';

                        imaxAmp = max(max(iwfAll,[],2)-min(iwfAll,[],2));  % max amplitude in each channel
                        maxAmp = max([maxAmp imaxAmp]);
                    end

                    allLines = [];
                    yscale = 400/maxAmp;
                    for i = 1:nUnit
                        xdata = (1:size(wfAll{i}.wf,2)) + wfAll{i}.xc;
                        ydata = -wfAll{i}.wf*yscale + wfAll{i}.yc;
                        for j = 1:size(xdata, 1)
                            if j == 1
                                iline = plot(xdata(j,:), ydata(j,:), 'Color', allColor(i,:), ...
                                    'LineStyle', '-', 'LineWidth', 0.5);
                                allLines = [allLines iline];
                            else
                                plot(xdata(j,:), ydata(j,:), 'Color', allColor(i,:), ...
                                    'LineStyle', '-', 'LineWidth', 0.5);
                            end
                        end
                    end
            end

            if options.waveType == "MultiChannel"
                if nUnit > 1
                    le = legend(allLines, nameUnit, "Box", "off", ...
                        "Units", "centimeters", "Position", [xmap(1+nUnit)+xgap ymap(1)+ygap 1 1], ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    le.ItemTokenSize = [15,18];
                else
                    title(ha0, nameUnit, "FontSize", fontSize.Label, "FontName", "Arial");
                end
            else
                if nUnit > 1  % add legend if more than one unit
                    le = legend(nameUnit, "Box", "off", ...
                        "Units", "centimeters", "Position", [xmap(1+nUnit)+xgap ymap(1)+ygap 1 1], ...
                        "FontSize", fontSize.Label, "FontName", "Arial");
                    le.ItemTokenSize = [15,18];
                else
                    le = legend(nameUnit, "Box", "off", ...
                        "Units", "centimeters", "Location", 'southwest', ...
                        "FontSize", fontSize.Title, "FontName", "Arial");
                    le.ItemTokenSize = [12,15];
                end
            end

            % Spike range raster
            ha00 = axes;
            set(ha00, 'Units', 'centimeters', 'Position', [xmap2(1) ymap(end) axeSizeRast], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'XLim', xLim.tRange, 'XTick', [0 0.5 1]*xLim.tRange(end), ...
                'XTickLabel', string([0 50 100]*round(xLim.tRange(end)/100000)), ...
                'YLim', yLim.spkRange, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            for i = 1:nUnit
                scatter(spkTime2Plot{i}, spkRange2Plot{i}, 10, 'o', ...
                    'MarkerFaceColor', allColor(i,:), 'MarkerFaceAlpha', alpha.spkRange, ...
                    'MarkerEdgeColor', 'none', 'MarkerEdgeAlpha', alpha.spkRange);
            end
            xlabel("Session time (sec)", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("spk amp x 4 (uV)", "FontSize", fontSize.Label, "FontName", "Arial");
            
            % Spike range histogram
            ha000 = axes;
            set(ha000, 'Units', 'centimeters', 'Position', [xmap2(2) ymap(end) axeSizeHist], ...
                'NextPlot', 'add', 'TickDir', 'out', 'TickLength', tickLen, ...
                'YLim', yLim.spkRange, 'YTick', [], 'YTickLabel', {}, ...
                'FontSize', fontSize.Axes, 'FontName', 'Arial');
            yEdge.spkRange = yLim.spkRange(1):20:yLim.spkRange(2);
            for i = 1:nUnit
                histogram(ha000, spkRange2Plot{i}, yEdge.spkRange, 'Orientation', 'horizontal', ...
                    'EdgeAlpha', 0.02, 'FaceColor', allColor(i,:));
            end

            ha0000 = axes;
            % Add title
            set(ha0000, "Units", "centimeters", ...
                "Position", [xmap(1) ymap(1)+axeSize1(2) fullWidth 0.5]);
            axis off;
            title(titleText, "FontSize", fontSize.Title, "FontWeight", "bold", "FontName", "Arial");

        end

        function plotSortResultAll(obj, options)
            arguments
                obj
                options.waveType string {mustBeMember(options.waveType, ["Normal", "Heatmap", "MultiChannel"])} = "MultiChannel"
                options.printPNG = true
                options.printEPS = false
                options.printFIG = false
            end

            allChannels = unique(cell2mat(obj.SpikeTable.ch), "rows", "sorted");
            for i = 1:length(allChannels)
                Fig = obj.plotSortResult(allChannels(i), "inputType", "Channel", "waveType", options.waveType);

                %% Save Fig
                [~,~] = mkdir(fullfile(pwd, "Fig", "Sorting"));
                savename = fullfile(pwd, "Fig", "Sorting", "Ch"+num2str(allChannels(i))+"_SortingResults");
                if options.printPNG
                    print(Fig, '-dpng', savename);
                end
                if options.printEPS
                    print(Fig, '-depsc2', savename);
                end
                if options.printFIG
                    saveas(Fig, savename, 'fig');
                end
            end
        end

        function calCrossCorrelation(obj)

            isiEdges = 0:1:50;
            wfAll = obj.SpikeTable.waveforms_mean;  % N*1 cell, each cell: waveform of a unit in all channels
            stAll = obj.SpikeTable.spike_times_r;   % N*1 cell, each cell: spike time ... in all ...
            xtmap = obj.ChanMap.xtrodeMap;  % map of #tetrode or #shank
            nUnits = length(wfAll);
            wfCorrelation  = zeros(nUnits, nUnits); wfCorrTable  = [];
            isiCorrelation = zeros(nUnits, nUnits); isiCorrTable = [];
            for i = 1:nUnits
                for j = 1:nUnits
                    if i == j
                        wfCorrelation(i, j)  = 0;
                        isiCorrelation(i, j) = 0;
                    else
                        if xtmap(obj.SpikeTable.ch{i}) ~= xtmap(obj.SpikeTable.ch{j})
                            wfCorrelation(i, j)  = 0;
                            isiCorrelation(i, j) = 0;
                        else
                            wfCorr = corrcoef(reshape(wfAll{i}, 1, []), reshape(wfAll{j}, 1, []));
                            wfCorrelation(i, j) = atanh(wfCorr(1, 2));
                            iISI = diff(stAll{i}); jISI = diff(stAll{j});
                            isiCorr = corrcoef(histcounts(iISI, isiEdges), histcounts(jISI, isiEdges));
                            isiCorrelation(i, j) = atanh(isiCorr(1, 2));
                            if i > j
                                wfCorrTable = [wfCorrTable; j i wfCorrelation(i, j)];  % let t(1,:) ~ smaller #unit
                            elseif i < j
                                isiCorrTable = [isiCorrTable; i j isiCorrelation(i, j)];
                            end
                        end
                    end
                end
            end

            [~, idx] = sort(wfCorrTable(:,3), "descend");  
            wfCorrTable = wfCorrTable(idx, :);
            [~, idx] = sort(isiCorrTable(:,3), "descend"); 
            isiCorrTable = isiCorrTable(idx, :);

            CrossCorrelation.ISI = array2table(isiCorrTable, "VariableNames", ["UnitA", "UnitB", "Corr"]);
            CrossCorrelation.Waveform = array2table(wfCorrTable, "VariableNames", ["UnitA", "UnitB", "Corr"]);
            save("CrossCorrelation.mat", "CrossCorrelation", "-mat");

            % Plot
            fontSize = struct("Axes", 7, "Label", 9, "Title", 10);
            cTab10 = tab10(10); bgColor = Pastel1(9);
            cBlue = cTab10(1,:); cRed = cTab10(4,:);
            wfColormap  = customcolormap([0 1], [cRed;  bgColor(6,:)]);
            isiColormap = customcolormap([0 1], [cBlue; bgColor(6,:)]);
            xstart = 1.2; ystart = 0.5; xgap = 1.5; ygap = 1.5;
            axeSize = [5 5]; tblSize = [axeSize(1) 6];

            wflen = size(wfCorrTable,1);
            if wflen > 10
                idx = 1:10;
            else
                idx = 1:wflen;
                tblSize(2) = tblSize(2)*(wflen+2)/12;
            end

            xmap = [xstart, ...
                    xstart + xgap*1 + axeSize(1), ...
                    xstart + xgap*2 + axeSize(1)*2];
            ymap = [ystart, ...
                    ystart + ygap*1 + tblSize(2)];
            ymap = fliplr(ymap);
            figSize = [xmap(end), ymap(1)+ygap*1.5+axeSize(2)];

            Fig = figure(1); clf(Fig, "reset");
            set(Fig, 'units', 'centimeters', 'color', 'w', ...
                'position', [2 2 figSize], 'paperpositionmode', 'auto');

            ha1 = axes;
            set(ha1, 'Units', 'centimeters', 'Position', [xmap(1) ymap(1) axeSize], ...
                    'NextPlot', 'add', 'TickDir', 'out', 'FontSize', fontSize.Axes, 'FontName', 'Arial', ...
                    'XLim', [0.5 nUnits+0.5], 'YLim', [0.5 nUnits+0.5]);
            imagesc(ha1, wfCorrelation, [0 2.5]);
            title("Waveform correlation coef.", ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            ylabel("# Unit", "FontSize", fontSize.Label, "FontName", "Arial");
            xlabel("# Unit", "FontSize", fontSize.Label, "FontName", "Arial");
            colormap(ha1, wfColormap);

            ha2 = axes;
            set(ha2, 'Units', 'centimeters', 'Position', [xmap(2) ymap(1) axeSize], ...
                    'NextPlot', 'add', 'TickDir', 'out', 'FontSize', fontSize.Axes, 'FontName', 'Arial', ...
                    'XLim', [0.5 nUnits+0.5], 'YLim', [0.5 nUnits+0.5]);
            imagesc(ha2, isiCorrelation, [0 3]);
            title("ISI correlation coef.", ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "bold");
            xlabel("# Unit", "FontSize", fontSize.Label, "FontName", "Arial");
            ylabel("# Unit", "FontSize", fontSize.Label, "FontName", "Arial");
            colormap(ha2, isiColormap);

            % Display waveform correlation coefficients
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "normal", ...
                "Position", [xmap(1) ymap(2) tblSize(1)/4 tblSize(2)], ...
                "String", ["Unit A"; "- - - - -"; num2str(wfCorrTable(idx, 1))]);
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "normal", ...
                "Position", [xmap(1)+tblSize(1)/4 ymap(2) tblSize(1)/4 tblSize(2)], ...
                "String", ["Unit B"; "- - - - -"; num2str(wfCorrTable(idx, 2))]);
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "normal", ...
                "Position", [xmap(1)+tblSize(1)/2 ymap(2) tblSize(1)/2 tblSize(2)], ...
                "String", ["Corr."; "- - - - - - - - - -"; num2str(wfCorrTable(idx, 3), "%.3f")]);
            
            % Display isi correlation coefficients
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "normal", ...
                "Position", [xmap(2) ymap(2) tblSize(1)/4 tblSize(2)], ...
                "String", ["Unit A"; "- - - - -"; num2str(isiCorrTable(idx, 1))]);
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "normal", ...
                "Position", [xmap(2)+tblSize(1)/4 ymap(2) tblSize(1)/4 tblSize(2)], ...
                "String", ["Unit B"; "- - - - -"; num2str(isiCorrTable(idx, 2))]);
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title, "FontName", "Arial", "FontWeight", "normal", ...
                "Position", [xmap(2)+tblSize(1)/2 ymap(2) tblSize(1)/2 tblSize(2)], ...
                "String", ["Corr."; "- - - - - - - - - -"; num2str(isiCorrTable(idx, 3), "%.3f")]);
            
            % Add title
            uicontrol("Style", "text", "Units", "centimeters", "BackgroundColor", 'w', ...
                "FontSize", fontSize.Title+1, "FontName", "Arial", "FontWeight", "bold", ...
                "Position", [xmap(1) ymap(1)+axeSize(2)+ygap/2 2*axeSize(1)+xgap 1], ...
                "String", "Cross-correlation");
            
            % Save figure
            [~,~] = mkdir(fullfile(pwd, "Fig", "Sorting"));
            savename = fullfile(pwd, "Fig", "Sorting", "CrossCorrelation");
            print(Fig, '-dpng', savename);
        end
        
        function checkSimilarity(obj, options)
            arguments
                obj
                options.Threshold = 1.5  % threshold of cross correlation coefficients
                options.Indicator string{mustBeMember(options.Indicator, ["Waveform","ISI"])} = "Waveform"
            end
%             if isempty(dir("CrossCorrelation.mat"))
            obj.calCrossCorrelation;
%             end
            load("CrossCorrelation.mat", "CrossCorrelation");
            cc = CrossCorrelation.(options.Indicator);
            idxCheck = find(cc.Corr > options.Threshold);
            if ~isempty(idxCheck)
                for i = 1:length(idxCheck)
                    Fig = obj.plotSortResult([cc.UnitA(i) cc.UnitB(i)], ...
                        "inputType", "Unit", "waveType", "MultiChannel");
                    [~,~] = mkdir(fullfile(pwd, "Fig", "Sorting"));
                    savename = fullfile(pwd, "Fig", "Sorting", ...
                        "CheckSimilarity_Unit"+num2str(cc.UnitA(i))+"_vs_"+num2str(cc.UnitB(i)));
                    print(Fig, '-dpng', savename);
                    disp("Unit pair(s) "+num2str(i)+" of "+num2str(length(idxCheck))+" checked")
                end
            else
                disp("**** All units are unique :) ****");
            end
        end

    end
end

