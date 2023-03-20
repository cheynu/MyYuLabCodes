classdef BuildR < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        Panel                       matlab.ui.container.Panel
        EphysSegsEditField          matlab.ui.control.EditField
        EphysSegsEditFieldLabel     matlab.ui.control.Label
        BlankoutEditField           matlab.ui.control.EditField
        BlankoutEditFieldLabel      matlab.ui.control.Label
        BpodProtocolDropDown        matlab.ui.control.DropDown
        BpodProtocolDropDownLabel   matlab.ui.control.Label
        DIversionDropDown           matlab.ui.control.DropDown
        DIversionDropDownLabel      matlab.ui.control.Label
        KornblumCheckBox            matlab.ui.control.CheckBox
        Panel_2                     matlab.ui.container.Panel
        SpkmaxEditField             matlab.ui.control.NumericEditField
        SpkmaxEditFieldLabel        matlab.ui.control.Label
        PostEditField               matlab.ui.control.NumericEditField
        PostEditFieldLabel          matlab.ui.control.Label
        PreEditField                matlab.ui.control.NumericEditField
        PreEditFieldLabel           matlab.ui.control.Label
        mean_subCheckBox            matlab.ui.control.CheckBox
        ProtocolDropDown            matlab.ui.control.DropDown
        ProtocolDropDownLabel       matlab.ui.control.Label
        PlotpopulationButton_2      matlab.ui.control.Button
        LoadButton                  matlab.ui.control.Button
        PlotAllPSTHsButton          matlab.ui.control.Button
        PlotPSTHButton              matlab.ui.control.Button
        UnitsInCh                   matlab.ui.control.DropDown
        CheckunitsButton            matlab.ui.control.Button
        SaveGUIfigButton            matlab.ui.control.Button
        ExperimenterEditField       matlab.ui.control.EditField
        ExperimenterEditFieldLabel  matlab.ui.control.Label
        SegmentsDropDown            matlab.ui.control.DropDown
        SegmentsDropDownLabel       matlab.ui.control.Label
        BuildButton                 matlab.ui.control.Button
        BpodfileLabel               matlab.ui.control.Label
        MEDfileLabel                matlab.ui.control.Label
        ANMEditField                matlab.ui.control.EditField
        ANMEditFieldLabel           matlab.ui.control.Label
        BuildrarrayButton           matlab.ui.control.Button
        UnitsButtonGroup            matlab.ui.container.ButtonGroup
        PolytrodesEditField         matlab.ui.control.EditField
        PolytrodesEditFieldLabel    matlab.ui.control.Label
        EditField_32                matlab.ui.control.EditField
        EditField_31                matlab.ui.control.EditField
        EditField_30                matlab.ui.control.EditField
        EditField_29                matlab.ui.control.EditField
        EditField_28                matlab.ui.control.EditField
        EditField_27                matlab.ui.control.EditField
        EditField_26                matlab.ui.control.EditField
        EditField_25                matlab.ui.control.EditField
        EditField_24                matlab.ui.control.EditField
        EditField_23                matlab.ui.control.EditField
        EditField_22                matlab.ui.control.EditField
        EditField_21                matlab.ui.control.EditField
        EditField_20                matlab.ui.control.EditField
        EditField_19                matlab.ui.control.EditField
        EditField_18                matlab.ui.control.EditField
        EditField_17                matlab.ui.control.EditField
        EditField_16                matlab.ui.control.EditField
        EditField_15                matlab.ui.control.EditField
        EditField_14                matlab.ui.control.EditField
        EditField_13                matlab.ui.control.EditField
        EditField_12                matlab.ui.control.EditField
        EditField_11                matlab.ui.control.EditField
        EditField_10                matlab.ui.control.EditField
        EditField_9                 matlab.ui.control.EditField
        EditField_8                 matlab.ui.control.EditField
        EditField_7                 matlab.ui.control.EditField
        EditField_6                 matlab.ui.control.EditField
        EditField_5                 matlab.ui.control.EditField
        EditField_4                 matlab.ui.control.EditField
        EditField_3                 matlab.ui.control.EditField
        EditField_2                 matlab.ui.control.EditField
        EditField_1                 matlab.ui.control.EditField
        Ch32Button                  matlab.ui.control.RadioButton
        Ch31Button                  matlab.ui.control.RadioButton
        Ch30Button                  matlab.ui.control.RadioButton
        Ch29Button                  matlab.ui.control.RadioButton
        Ch28Button                  matlab.ui.control.RadioButton
        Ch27Button                  matlab.ui.control.RadioButton
        Ch26Button                  matlab.ui.control.RadioButton
        Ch25Button                  matlab.ui.control.RadioButton
        Ch24Button                  matlab.ui.control.RadioButton
        Ch23Button                  matlab.ui.control.RadioButton
        Ch22Button                  matlab.ui.control.RadioButton
        Ch21Button                  matlab.ui.control.RadioButton
        Ch20Button                  matlab.ui.control.RadioButton
        Ch19Button                  matlab.ui.control.RadioButton
        Ch18Button                  matlab.ui.control.RadioButton
        Ch17Button                  matlab.ui.control.RadioButton
        Ch16Button                  matlab.ui.control.RadioButton
        Ch15Button                  matlab.ui.control.RadioButton
        Ch14Button                  matlab.ui.control.RadioButton
        Ch13Button                  matlab.ui.control.RadioButton
        Ch12Button                  matlab.ui.control.RadioButton
        Ch11Button                  matlab.ui.control.RadioButton
        Ch10Button                  matlab.ui.control.RadioButton
        Ch9Button                   matlab.ui.control.RadioButton
        Ch8Button                   matlab.ui.control.RadioButton
        Ch7Button                   matlab.ui.control.RadioButton
        Ch6Button                   matlab.ui.control.RadioButton
        Ch5Button                   matlab.ui.control.RadioButton
        Ch4Button                   matlab.ui.control.RadioButton
        Ch3Button                   matlab.ui.control.RadioButton
        Ch2Button                   matlab.ui.control.RadioButton
        Ch1Button                   matlab.ui.control.RadioButton
        LoadBpodfileButton          matlab.ui.control.StateButton
        LoadMEDfileButton           matlab.ui.control.StateButton
        UIAxesBehav                 matlab.ui.control.UIAxes
        UIAxesRaster                matlab.ui.control.UIAxes
        ContextMenu                 matlab.ui.container.ContextMenu
        Menu                        matlab.ui.container.Menu
        Menu2                       matlab.ui.container.Menu
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: LoadMEDfileButton
        function LoadMEDfileButtonValueChanged(app, event)
            value = app.LoadMEDfileButton.Value;

            % Look for MED file
            MEDFile = dir('*Subject*.txt');

            if isempty(MEDFile)
                disp('Check folder');
            end

            % Compute behavioral data from MED file
            if app.KornblumCheckBox.Value == 1
                kb = KornblumClass(MEDFile.name);
                kb.plot();
                kb.print();
                kb.save();                
                track_training_progress_advanced_KornblumStyle(MEDFile.name);
            else
                track_training_progress_advanced(MEDFile.name);
            end

            behfile= dir('B_*mat');
            load(fullfile(behfile.folder, behfile.name))

            % place b
            app.MEDfileLabel.UserData = b; 
            app.MEDfileLabel.Text = MEDFile.name;
            
        end

        % Drop down opening function: SegmentsDropDown
        function SegmentsDropDownOpening(app, event)
            x = dir('datafile*.nev');
            AllSegments = arrayfun(@(x)x.name, x, 'UniformOutput', false);
            app.SegmentsDropDown.Items = AllSegments; 
        end

        % Value changed function: LoadBpodfileButton
        function LoadBpodfileButtonValueChanged(app, event)
            value = app.LoadBpodfileButton.Value;
            name = app.ANMEditField.Value;
            BpodFile = dir([name '*.mat']);

            if ~isempty(BpodFile)
                app.BpodfileLabel.Text = BpodFile.name;
                load(BpodFile.name);
                app.BpodfileLabel.UserData = SessionData;
            end

        end

        % Button pushed function: BuildButton
        function BuildButtonPushed(app, event)

            % Check spks
            units = {};
            for i = 1:32
                ivalue = strrep(eval(['app.EditField_' num2str(i) '.Value']), ' ', '');
                if ~isempty(ivalue)
                    IndNew=size(units, 1)+1;
                    units{IndNew, 1} = i;
                    units{IndNew, 2} = ivalue;
                    units{IndNew, 3} = [];
                end
            end

            BlankOut = [];
            if ~isempty(app.BlankoutEditField.Value)
                BlankOut = str2num(app.BlankoutEditField.Value);
                BlankOut = reshape(BlankOut, 2, []);
            end

            % here we build r array based on available information
            b                      =        app.MEDfileLabel.UserData;
            % return FP if there is no FP (wait 1/2 sessions)

            if isempty(b.FPs)  
                b = UpdateWaitB(b); % add FP
            end

            SessionData    =       app.BpodfileLabel.UserData;
            blocks              =       app.SegmentsDropDown.Items;
            EventOutAll = [];
% 
            %% 

            for ib=1:length(blocks)

                nevfile = blocks{ib};
                openNEV(nevfile, 'report', 'read')  % open ‘datafile###.nev’, create “datafile###.mat”
                load([nevfile(1:11) '.mat']);
                switch app.DIversionDropDown.Value
                    case 'Version4'
                        EventOut = DIO_Events4(NEV); % create
                    case 'Version5'
                        EventOut = DIO_Events5(NEV); % create
                        % Poke signals are incorrect. Update poke from bpod.  10/4/2022
                        EventOut.Onset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                        EventOut.Offset{strcmp(EventOut.EventsLabels, 'Poke')} = [];
                    case 'Version6'
                        EventOut = DIO_Events6(NEV);
                end

                %  update poke information in EventOut with bpod events
                switch app.BpodProtocolDropDown.Value
                    case 'OptoRecording'
                        %  read bpod events
                        bpodevents = Bpod_Events_MedOptoRecording(SessionData);
                        EventOut = UpdateDIOMedOpto(EventOut, bpodevents);
                    case 'OptoRecordingMix'  % optogenetic stimulation was applied at the onset of different events, we need to extract those times, and align them to blackrock's time
                        %  read bpod events                
                        bpodevents = Bpod_Events_MedOptoRecMix(SessionData);
                        EventOut = UpdateDIOMedOptoRecMix(EventOut, bpodevents);
                    case 'Medlick'
                        bpodevents = Bpod_Events_MedLick(SessionData);
                        EventOut = UpdateDIO_MedLick(EventOut, bpodevents);
                end
                % update Trigger signal and add a few behavioral events

                EventOut = AlignMED2BR(EventOut, b);

                EventOut.Meta.Subject = app.ANMEditField.Value;
                EventOut.Meta.Experimenter = app.ExperimenterEditField.Value;

                if isfield(EventOut, 'Subject')
                    EventOut = rmfield(EventOut, 'Subject');
                end
                if isfield(EventOut, 'Experimenter')
                    EventOut = rmfield(EventOut, 'Experimenter');
                end
                if ib ==1
                    EventOutAll=EventOut;
                else
                    EventOutAll(ib)=EventOut;
                end
            end

            save EventOutAll EventOutAll

            %% construct an array (r) with aligned behavior, spikes and LFP data.
            % name is r

            % turn everything in minutes
            % single unit: 1; multiunit: 2
            r=[];

            for i =1 :length(EventOutAll)
                r.Meta(i) = EventOutAll(i).Meta;
            end

            dBlockOnset = 0;

            % calculate time difference between different blocks
            if length(blocks)>1
                dBlockOnset = zeros(1, length(blocks)-1);
                for i=1:length(dBlockOnset)
                    dt_i = EventOutAll(i+1).Meta.DateTimeRaw-EventOutAll(1).Meta.DateTimeRaw;
                    dBlockOnset(i)=dt_i(end)+dt_i(end-1)*1000+dt_i(end-2)*1000*60+dt_i(end-3)*1000*60*60;  % in ms
                end

                dBlockOnset=[0 dBlockOnset];
            end

            r.Behavior.Labels={'FrameOn', 'FrameOff', 'LeverPress', 'Trigger', 'LeverRelease', 'GoodPress', 'GoodRelease',...
                'ValveOnset', 'ValveOffset', 'PokeOnset', 'PokeOffset' , 'BadPokeFirstIn', 'BadPokeFirstOut'};
            r.Behavior.LabelMarkers = [1:length(r.Behavior.Labels)];

            r.Behavior.CorrectIndex                 =      [];
            r.Behavior.PrematureIndex            =      [];
            r.Behavior.LateIndex                      =      [];
            r.Behavior.DarkIndex                     =       [];
            r.Behavior.Foreperiods                  =       [];
            r.Behavior.EventTimings = [];
            r.Behavior.EventMarkers = [];
            pressnum = 0;
            r.Behavior.CueIndex                      =       [];

            for i = 1:length(EventOutAll)

                if i>1
                    pressnum = pressnum +  length(EventOutAll(i-1).Onset{strcmp(EventOutAll(i-1).EventsLabels, 'LeverPress')});
                end;

                % add frame signal: 1 on, 2 off
                indframe = find(strcmp(EventOutAll(i).EventsLabels, 'Frame'));
                eventonset = EventOutAll(i).Onset{indframe}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indframe}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1); ones(length(eventoffset), 1)*2]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];
                EventNames{1} = 'FrameOn';
                EventNames{2} =  'FrameOff';

                % add leverpress onset and offset signal: 3 and 5
                indleverpress= find(strcmp(EventOutAll(i).EventsLabels, 'LeverPress'));
                eventonset = EventOutAll(i).Onset{indleverpress}+dBlockOnset(i);
                eventonset_press = EventOutAll(i).Onset{indleverpress};
                eventoffset = EventOutAll(i).Offset{indleverpress}+dBlockOnset(i);
                eventoffset_press =  EventOutAll(i).Offset{indleverpress};
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1)*3; ones(length(eventoffset),1)*5];
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

                if i==1
                    r.Behavior.CorrectIndex         = EventOutAll(i).PerfIndex{ find(strcmp(EventOutAll(i).Performance, 'Correct'))};
                    r.Behavior.PrematureIndex    = EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Premature'))};
                    r.Behavior.LateIndex              = EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Late'))};
                    r.Behavior.DarkIndex             = EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Dark'))};
                    r.Behavior.CueIndex              =        transpose(EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Cue'))});
                else
                    r.Behavior.CorrectIndex              =   [r.Behavior.CorrectIndex; EventOutAll(i).PerfIndex{ find(strcmp(EventOutAll(i).Performance, 'Correct'))}+pressnum];
                    r.Behavior.PrematureIndex            =   [r.Behavior.PrematureIndex; EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Premature'))}+pressnum];
                    r.Behavior.LateIndex                     =   [r.Behavior.LateIndex;EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Late'))}+pressnum];
                    r.Behavior.DarkIndex                     =   [r.Behavior.DarkIndex; EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Dark'))}+pressnum];
                    r.Behavior.CueIndex              =          [ r.Behavior.CueIndex; transpose(EventOutAll(i).PerfIndex{find(strcmp(EventOutAll(i).Performance, 'Cue'))})];
                end;

                r.Behavior.Foreperiods                  = [r.Behavior.Foreperiods; EventOutAll(i).FPs'];

                % add trigger stimulus signal: 4
                indtriggers= find(strcmp(EventOutAll(i).EventsLabels, 'Trigger'));
                eventonset = EventOutAll(i).Onset{indtriggers}+dBlockOnset(i);
                triggeronset = EventOutAll(i).Onset{indtriggers};
                if size(eventonset, 1)<size(eventonset, 2)
                    eventonset = eventonset';
                end;

                indevent = [ones(length(eventonset), 1)*4];
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];

                figure(11); clf
                axes('nextplot', 'add', 'ylim', [0 10])

                plot(triggeronset, 4, 'go')
                text(triggeronset(1), 4.2, 'trigger')

                % add good press and release signal: 6 and 7
                indgoodrelease= find(strcmp(EventOutAll(i).EventsLabels, 'GoodRelease'));
                eventonset = EventOutAll(i).Onset{indgoodrelease}+dBlockOnset(i);
                eventonset_goodrelease = EventOutAll(i).Onset{indgoodrelease};
                indevent = [ones(length(eventonset), 1)*7]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];
                plot(eventonset_goodrelease, 7, 'ko')
                text(eventonset_goodrelease(1), 7.2, 'good release')


                eventonset_goodpress = zeros(length(eventonset_goodrelease), 1);
                for in=1:length(EventOutAll(i).Onset{indgoodrelease})
                    time_of_goodrelease = eventonset_goodrelease(in);
                    [~, index] = min(abs(time_of_goodrelease-eventoffset_press));
                    % find the onset
                    ind_onset = find(eventonset_press-eventoffset_press(index)<0, 1, 'last'); % the last onset that is less than the off time
                    if ~isempty(ind_onset)
                        eventonset_goodpress(in) = eventonset_press(ind_onset);
                    end
                end;

                eventonset = eventonset_goodpress+dBlockOnset(i);
                indevent = [ones(length(eventonset), 1)*6];
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventonset];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indevent];

                plot(eventonset_goodpress, 6, 'k*')
                text(eventonset_goodpress(1), 6.2, 'good press')

                % add valve onset and offset signals: 8 and 9
                indvalve= find(strcmp(EventOutAll(i).EventsLabels, 'Valve'));
                eventonset = EventOutAll(i).Onset{indvalve}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indvalve}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1)*8; ones(length(eventoffset), 1)*9]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

                plot(EventOutAll(i).Onset{indvalve}, 8, 'm^')
                text(EventOutAll(i).Onset{indvalve}(1), 8.2, 'valve')

                % add poke onset and offset signals: 10 and 11
                indpoke= find(strcmp(EventOutAll(i).EventsLabels, 'Poke'));
                eventonset = EventOutAll(i).Onset{indpoke}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indpoke}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [ones(length(eventonset), 1)*10; ones(length(eventoffset),1)*11]; % frame onset  1; frame offset 2
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

                % add badpoke signal: 12 on, 13 off
                indbadpoke = find(strcmp(EventOutAll(i).EventsLabels, 'BadPoke'));
                eventonset = EventOutAll(i).Onset{indbadpoke}+dBlockOnset(i);
                eventoffset = EventOutAll(i).Offset{indbadpoke}+dBlockOnset(i);
                eventmix = [eventonset; eventoffset];
                indeventmix = [12*ones(length(eventonset), 1); 13*ones(length(eventoffset), 1)]; % bad poke onset  12; badpoke offset 13
                r.Behavior.EventTimings = [r.Behavior.EventTimings; eventmix];
                r.Behavior.EventMarkers = [r.Behavior.EventMarkers; indeventmix];

            end;

            % sort timing
            [r.Behavior.EventTimings, index_timing] = sort(r.Behavior.EventTimings);
            r.Behavior.EventMarkers = r.Behavior.EventMarkers(index_timing);

            ind_blankpresses = [];
            % BlankOut bad signals or data that won't be included
            if ~isempty(BlankOut)
                for m = 1:size(BlankOut, 2)
                    % check presses
                    t_presses = r.Behavior.EventTimings(r.Behavior.EventMarkers == 3);
                    ind_blankpresses = [ind_blankpresses find(t_presses>=BlankOut(1, m)*1000 & t_presses<=BlankOut(2, m)*1000)];
                    ind_blank = find(r.Behavior.EventTimings>=BlankOut(1, m)*1000 & r.Behavior.EventTimings<=BlankOut(2, m)*1000)
                    r.Behavior.EventTimings(ind_blank) =[];
                    r.Behavior.EventMarkers(ind_blank) =[];

                end;
            end;

            if ~isempty(ind_blankpresses)
                PressIndexOrg = [1:length(r.Behavior.Foreperiods)];

                PressIndexAfter = PressIndexOrg;
                PressIndexAfter(ind_blankpresses) = [];

                r.Behavior.CueIndex(ind_blankpresses, :) = [];
                r.Behavior.Foreperiods(ind_blankpresses) = [];

                PressIndexNew = [1:length(r.Behavior.Foreperiods)];

                %  Fix these variables.
                [~, indcorrectblank] = intersect(r.Behavior.CorrectIndex, ind_blankpresses);
                CorrectIndex_Corrected = r.Behavior.CorrectIndex;
                CorrectIndex_Corrected(indcorrectblank) = [];
                [~, indcorrect_new] = intersect(PressIndexAfter, CorrectIndex_Corrected);
                r.Behavior.CorrectIndex = PressIndexNew(indcorrect_new);

                [~, indprematureblank] = intersect(r.Behavior.PrematureIndex, ind_blankpresses);                
                PrematureIndex_Corrected = r.Behavior.PrematureIndex;
                PrematureIndex_Corrected(indprematureblank) = [];
                [~, indpremature_new] = intersect(PressIndexAfter, PrematureIndex_Corrected);
                r.Behavior.PrematureIndex = PressIndexNew(indpremature_new);

                [~, indlateblank] = intersect(r.Behavior.LateIndex, ind_blankpresses);
                LateIndex_Corrected = r.Behavior.LateIndex;
                LateIndex_Corrected(indlateblank) = [];
                [~, indlate_new] = intersect(PressIndexAfter, LateIndex_Corrected);
                r.Behavior.LateIndex = PressIndexNew(indlate_new);

                [~, inddarkblank] = intersect(r.Behavior.DarkIndex, ind_blankpresses);
                DarkIndex_Corrected = r.Behavior.DarkIndex;
                DarkIndex_Corrected(inddarkblank) = [];
                [~, inddark_new] = intersect(PressIndexAfter, DarkIndex_Corrected);
                r.Behavior.DarkIndex = PressIndexNew(inddark_new);
            end;


%%      plot behavior data
            app.UIAxesBehav.NextPlot = 'add';
            app.UIAxesBehav.XLim = [0 max(r.Behavior.EventTimings/(1000))]; % in second
            app.UIAxesBehav.YTick = [1:length(r.Behavior.Labels)];
            app.UIAxesBehav.YTickLabel = r.Behavior.Labels;

            plot(app.UIAxesBehav, [r.Behavior.EventTimings/(1000)], [r.Behavior.EventMarkers],'o', 'color', 'k','markersize', 3, 'linewidth', 1)
            line(app.UIAxesBehav, [0 max(r.Behavior.EventTimings/(1000))], [1:length(r.Behavior.Labels); 1:length(r.Behavior.Labels)], 'color', 'k')


            r.Units.Channels                                = [1:16 17:32];
            r.Units.Profile                                    = units;
            r.Units.Definition                               = {'channel_id cluster_id unit_type polytrode', '1: single unit', '2: multi unit'};
            r.Units.SpikeNotes                             = [];

            for i                                              = 1:size(units, 1)
                ich = units{i, 1};
                sorting_code                             = units{i, 2};
                for k                                              = 1:length(sorting_code)
                    switch sorting_code(k)
                        case 'm'
                            r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 2 0];
                        case 's'
                            r.Units.SpikeNotes                                   = [r.Units.SpikeNotes; units{i, 1} k 1 0];
                    end;
                end
            end;

            spkchs = unique(r.Units.SpikeNotes(:, 1));
            allcolors                                          = varycolor(length(spkchs));

            app.UIAxesRaster.XLim = app.UIAxesBehav.XLim;
            app.UIAxesRaster.YLim = [0 size(r.Units.SpikeNotes , 1)+1];
            app.UIAxesRaster.NextPlot = 'Add';

            % put spikes
            if exist(['chdat1.mat'])>0
                raw = load('chdat1.mat');
            else
                raw                  = load(['chdat' num2str(r.Units.SpikeNotes(1, 1)) '.mat']);
            end;

            torg = raw.index; % also in ms 
            tnew = [1:length(raw.index)]*1000/30000; % tnew in ms

            % Sometimes, we only include the later sessions. Check
            % EphysSegsEditField for this information
            EphysSegs = [];
            if ~isempty(app.EphysSegsEditField.Value)
                EphysSegs = str2num(app.EphysSegsEditField.Value);
            end;

            SegBegs         =           [1 1+find(diff(torg)>100)];
            SegEnds         =           [find(diff(torg)>100) length(torg)];

            if ~isempty(EphysSegs)
                for ks = 1:length(EphysSegs)
                    if EphysSegs(ks)==0
                        tnew([SegBegs(ks):SegEnds(ks)]) = NaN;
                    end;
                end;
            end;

            torg = torg - torg(find(~isnan(tnew), 1, 'first'));

            for i                                             = 1:size(r.Units.SpikeNotes, 1)
                channel_id                              = r.Units.SpikeNotes(i, 1);  % channel id
                cluster_id                                = r.Units.SpikeNotes(i, 2);  % cluster id
                r.Units.SpikeTimes(i)               =   struct('timings',  [], 'wave', []);
                DataDurationmSec                  = ceil(r.Meta(ib).DataDurationSec*1000); % in ms

                % load spike time:
                if app.mean_subCheckBox.Value == 1
                    spk_id                                                 = load(['times_chdat_meansub' num2str(channel_id) '.mat']);
                else
                    spk_id                                                 = load(['times_chdat' num2str(channel_id) '.mat']);
                end;
                spk_in_ms                                           = round((spk_id.cluster_class(spk_id.cluster_class(:, 1)==cluster_id, 2))); % this is not mapped to time in recording

                [~, spkindx]                                          =     intersect(tnew, spk_in_ms);
                spk_in_ms_new                                   =    round(torg(spkindx));

                r.Units.SpikeTimes(i).timings = [r.Units.SpikeTimes(i).timings;  spk_in_ms_new]; % in ms

                r.Units.SpikeTimes(i).wave=[r.Units.SpikeTimes(i).wave;  spk_id.spikes(spk_id.cluster_class(:, 1)==cluster_id, :)];

                x_plot                                             = r.Units.SpikeTimes(i).timings;
                x_plot                                             = [x_plot]/(1000);
                y_plot                                             =  i -1 + 0.8*rand(1, length(x_plot));

                if ~isempty(x_plot)
                    plot(app.UIAxesRaster, x_plot, y_plot,'.', 'color', allcolors(spkchs ==channel_id, :),'markersize', 4);
                end;

            end;

            % make sure UIAxesBehav and UIAxesRaster have the same width
            app.UIAxesBehav.Position=[450 50 660 352];
            app.UIAxesRaster.Position=[530 340 580 352];
            app.UIAxesRaster.UserData = r;

            % Final touch double check the alignment. 
            CorrectBehaviorEphysMapping(r); % this also save r in the current directory

%             close all
%             tic
%             save RTarrayAll r
%             toc
% 
%             load('RTarrayAll.mat')
            disp('~~~~~~~~~~~~~~~~~~')
            disp('~~~~~ R is ready ~~~~~')
            disp('~~~~~ Load RArray for further analysis ~~~~~')
        end

        % Button pushed function: SaveGUIfigButton
        function SaveGUIfigButtonPushed(app, event)
            % save current figure

            exportapp(app.UIFigure,'rArray.png')
            exportapp(app.UIFigure,'rArray.pdf')

        end

        % Button pushed function: CheckunitsButton
        function CheckunitsButtonPushed(app, event)
            % Making PSTHs
            % search for ratio button that is on 
            % Check spks
            iCh = [];

            for i = 1:32
                ivalue = eval(['app.Ch' num2str(i) 'Button' '.Value']);
                if ivalue

                iCh = i;  % channel index
                type_units          =       eval(['app.EditField_' num2str(i) '.Value']);
                type_units          =       cellstr(type_units');
                n_units               =       length(type_units);

                allUnits = {};
                for k =1:n_units
                    allUnits{k} = ['unit' num2str(k) '_' type_units{k}];
                end;

                app.UnitsInCh.Items = allUnits;
                app.UnitsInCh.Value = app.UnitsInCh.Items{1};
                app.UnitsInCh.UserData =  i;

                end;
            end;

            value = app.UnitsInCh.Value;
            all_Items = app.UnitsInCh.Items;
            r = app.UIAxesRaster.UserData;
            ich = app.UnitsInCh.UserData;
            ik = find(strcmp(all_Items, value));

            FR_range = max([app.SpkmaxEditField.Value 20]);

            % find out which one:
            ind_Unit = find(r.Units.SpikeNotes(:, 1)==ich & r.Units.SpikeNotes(:, 2)==ik);

            session_length = app.UIAxesRaster.XLim;

            if isempty(app.PlotPSTHButton.UserData)
                app.PlotPSTHButton.UserData = rectangle(app.UIAxesRaster, 'Position', [session_length(1) ind_Unit-1 diff(session_length) 1], 'linewidth', 2)
            else
                delete(app.PlotPSTHButton.UserData)
                app.PlotPSTHButton.UserData = rectangle(app.UIAxesRaster, 'Position', [session_length(1) ind_Unit-1 diff(session_length) 1], 'linewidth', 2)
            end;
        
        end

        % Value changed function: UnitsInCh
        function UnitsInChValueChanged(app, event)
            value = app.UnitsInCh.Value;
            all_Items = app.UnitsInCh.Items;
            r = app.UIAxesRaster.UserData;
            ich = app.UnitsInCh.UserData;
            ik = find(strcmp(all_Items, value));

            FR_range = max([app.SpkmaxEditField.Value 20]);

            % find out which one:
            ind_Unit = find(r.Units.SpikeNotes(:, 1)==ich & r.Units.SpikeNotes(:, 2)==ik);

            session_length = app.UIAxesRaster.XLim;

            if isempty(app.PlotPSTHButton.UserData)
                app.PlotPSTHButton.UserData = rectangle(app.UIAxesRaster, 'Position', [session_length(1) ind_Unit-1 diff(session_length) 1], 'linewidth', 2)
            else
                delete(app.PlotPSTHButton.UserData)
                app.PlotPSTHButton.UserData = rectangle(app.UIAxesRaster, 'Position', [session_length(1) ind_Unit-1 diff(session_length) 1], 'linewidth', 2)
            end;

        end

        % Button pushed function: PlotPSTHButton
        function PlotPSTHButtonPushed(app, event)
            value = app.UnitsInCh.Value;
            all_Items = app.UnitsInCh.Items;
            r = app.UIAxesRaster.UserData;
            ich = app.UnitsInCh.UserData;
            ik = find(strcmp(all_Items, value));

            FR_range = max([app.SpkmaxEditField.Value 20]);
            % find out which one:
            ind_Unit = find(r.Units.SpikeNotes(:, 1)==ich & r.Units.SpikeNotes(:, 2)==ik);
            session_length = app.UIAxesRaster.XLim;

            PrePress = app.PreEditField.Value;
            PostPress = app.PostEditField.Value;

            % plot PSTH
            switch app.ProtocolDropDown.Value
                case 'TwoFPs'
                    SRTSpikesV5(r, [ich, ik], 'FRrange',[0 FR_range], 'PressTimeDomain', [PrePress PostPress]);
                case {'Wait1', 'Wait2'}
                    SRTSpikesWait(r,[ich, ik], 'FRrange',[0 FR_range], 'PressTimeDomain', [PrePress PostPress]);
            end;

        end

        % Button pushed function: PlotAllPSTHsButton
        function PlotAllPSTHsButtonPushed(app, event)
            %plot population responses
            r = app.UIAxesRaster.UserData;

            FR_range = max([app.SpkmaxEditField.Value 20]);
            PrePress = app.PreEditField.Value;
            PostPress = app.PostEditField.Value;

            switch app.ProtocolDropDown.Value
                case 'TwoFPs'
                    for i =1: length(r.Units.SpikeTimes)
                        SRTSpikesV5(r, i, 'FRrange',[0 FR_range], 'Name', '', 'PressTimeDomain', [PrePress PostPress]);
                        close all;
                    end;
                case {'Wait1', 'Wait2'}
                    for i =1: length(r.Units.SpikeTimes)
                        SRTSpikesWait(r, i, 'FRrange',[0 FR_range], 'Name', '', 'PressTimeDomain', [PrePress PostPress]);
                        close all;
                    end;
            end;

% 
%             PSTHPop = SRTSpikesPopulation(r);
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)

            [filename, pathname, ~] = uigetfile({'RT*.mat','MAT-files (*.mat)'}, ...
                'Pick r array');
            load(filename)
            app.UIAxesRaster.UserData                =      r;
            app.ANMEditField.Value                      =      r.Meta(1).Subject;
            app.ExperimenterEditField.Value         =      r.Meta(1).Experimenter;
            % fill in spike information
             for i = 1:size(r.Units.Profile, 1)
                ich = r.Units.Profile{i, 1}; 
                iunits = strrep(r.Units.Profile{i, 2}, ' ', ''); 
                eval(['app.EditField_' num2str(ich) '.Value' '=' 'iunits']);
             end;
            app.UIAxesBehav.NextPlot = 'add';
            app.UIAxesBehav.XLim = [0 max(r.Behavior.EventTimings/(1000))]; % in second
            app.UIAxesBehav.YTick = [1:length(r.Behavior.Labels)];
            app.UIAxesBehav.YTickLabel = r.Behavior.Labels;

            plot(app.UIAxesBehav, [r.Behavior.EventTimings/(1000)], [r.Behavior.EventMarkers],'o', 'color', 'k','markersize', 3, 'linewidth', 1)
            line(app.UIAxesBehav, [0 max(r.Behavior.EventTimings/(1000))], [1:length(r.Behavior.Labels); 1:length(r.Behavior.Labels)], 'color', [0.8 0.8 0.8])

            spkchs = unique(r.Units.SpikeNotes(:, 1));
            allcolors                                          = varycolor(length(spkchs));

            app.UIAxesRaster.XLim = app.UIAxesBehav.XLim;
            app.UIAxesRaster.YLim = [0 size(r.Units.SpikeNotes , 1)+1];
            app.UIAxesRaster.NextPlot = 'Add';

            % put spikes
            for i                                              = 1:size(r.Units.SpikeNotes, 1)
                channel_id                                         = r.Units.SpikeNotes(i, 1);  % channel id
    
                x_plot                                             = r.Units.SpikeTimes(i).timings;
                x_plot                                             = [x_plot]/(1000);
                y_plot                                             =  i -1 + 0.8*rand(1, length(x_plot));

                if ~isempty(x_plot)
                    plot(app.UIAxesRaster, x_plot, y_plot,'.', 'color', allcolors(spkchs ==channel_id, :),'markersize', 4);
                end;

            end;

            % make sure UIAxesBehav and UIAxesRaster have the same width
            app.UIAxesBehav.Position=[450 50 660 352];
            app.UIAxesRaster.Position=[530 380 580 352];
            app.UIAxesRaster.UserData = r;

        end

        % Button pushed function: PlotpopulationButton_2
        function PlotpopulationButton_2Pushed(app, event)
            %plot population responses
            r = app.UIAxesRaster.UserData;
            % check if it is two-FP protocol or wait protocol
            switch app.ProtocolDropDown.Value
                case 'TwoFPs'
                    PSTHPop = SRTSpikesPopulation(r);
                case 'Wait1'
                    PSTHPop = SRTSpikesPopulationWait(r);
                case 'Wait2'
                    PSTHPop = SRTSpikesPopulationWait(r);
            end;
        end

        % Value changed function: DIversionDropDown
        function DIversionDropDownValueChanged(app, event)
            value = app.DIversionDropDown.Value;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 25 1180 818];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'65x'};
            app.GridLayout.RowHeight = {'65x'};

            % Create Panel
            app.Panel = uipanel(app.GridLayout);
            app.Panel.Layout.Row = 1;
            app.Panel.Layout.Column = 1;

            % Create UIAxesRaster
            app.UIAxesRaster = uiaxes(app.Panel);
            title(app.UIAxesRaster, {'Spikes'; ''; ''})
            xlabel(app.UIAxesRaster, {'seconds'; ''})
            zlabel(app.UIAxesRaster, 'Z')
            app.UIAxesRaster.FontName = 'DejaVu Sans';
            app.UIAxesRaster.ColorOrder = [0 0 1;1 0 0;0 0.5 0;0.62069 0 0;0.413793 0 0.758621;0.965517 0.517241 0.034483;0.448276 0.37931 0.241379;1 0.103448 0.724138;0.545 0.545 0.545;0.586207 0.827586 0.310345;0.965517 0.62069 0.862069;0.62069 0.758621 1];
            app.UIAxesRaster.TickDir = 'out';
            app.UIAxesRaster.Tag = 'beh';
            app.UIAxesRaster.Position = [600 394 500 352];

            % Create UIAxesBehav
            app.UIAxesBehav = uiaxes(app.Panel);
            title(app.UIAxesBehav, {'Behavior'; ''; ''})
            xlabel(app.UIAxesBehav, 'seconds')
            zlabel(app.UIAxesBehav, 'Z')
            app.UIAxesBehav.FontName = 'DejaVu Sans';
            app.UIAxesBehav.ColorOrder = [0 0 1;1 0 0;0 0.5 0;0.62069 0 0;0.413793 0 0.758621;0.965517 0.517241 0.034483;0.448276 0.37931 0.241379;1 0.103448 0.724138;0.545 0.545 0.545;0.586207 0.827586 0.310345;0.965517 0.62069 0.862069;0.62069 0.758621 1];
            app.UIAxesBehav.TickDir = 'out';
            app.UIAxesBehav.Tag = 'raster';
            app.UIAxesBehav.Position = [600 34 500 352];

            % Create LoadMEDfileButton
            app.LoadMEDfileButton = uibutton(app.Panel, 'state');
            app.LoadMEDfileButton.ValueChangedFcn = createCallbackFcn(app, @LoadMEDfileButtonValueChanged, true);
            app.LoadMEDfileButton.Text = {'Load MED file'; ''};
            app.LoadMEDfileButton.Position = [25 615 100 22];

            % Create LoadBpodfileButton
            app.LoadBpodfileButton = uibutton(app.Panel, 'state');
            app.LoadBpodfileButton.ValueChangedFcn = createCallbackFcn(app, @LoadBpodfileButtonValueChanged, true);
            app.LoadBpodfileButton.Text = {'Load Bpod file'; ''};
            app.LoadBpodfileButton.Position = [25 583 100 22];

            % Create UnitsButtonGroup
            app.UnitsButtonGroup = uibuttongroup(app.Panel);
            app.UnitsButtonGroup.Title = 'Units';
            app.UnitsButtonGroup.Position = [13 66 403 510];

            % Create Ch1Button
            app.Ch1Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch1Button.Text = {'Ch1'; ''};
            app.Ch1Button.Position = [11 455 58 22];
            app.Ch1Button.Value = true;

            % Create Ch2Button
            app.Ch2Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch2Button.Text = {'Ch2'; ''};
            app.Ch2Button.Position = [11 428 65 22];

            % Create Ch3Button
            app.Ch3Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch3Button.Text = {'Ch3'; ''};
            app.Ch3Button.Position = [11 401 65 22];

            % Create Ch4Button
            app.Ch4Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch4Button.Text = 'Ch4';
            app.Ch4Button.Position = [11 374 44 22];

            % Create Ch5Button
            app.Ch5Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch5Button.Text = 'Ch5';
            app.Ch5Button.Position = [11 347 44 22];

            % Create Ch6Button
            app.Ch6Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch6Button.Text = 'Ch6';
            app.Ch6Button.Position = [11 320 44 22];

            % Create Ch7Button
            app.Ch7Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch7Button.Text = 'Ch7';
            app.Ch7Button.Position = [11 294 44 22];

            % Create Ch8Button
            app.Ch8Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch8Button.Text = 'Ch8';
            app.Ch8Button.Position = [11 268 44 22];

            % Create Ch9Button
            app.Ch9Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch9Button.Text = 'Ch9';
            app.Ch9Button.Position = [11 242 44 22];

            % Create Ch10Button
            app.Ch10Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch10Button.Text = 'Ch10';
            app.Ch10Button.Position = [11 216 51 22];

            % Create Ch11Button
            app.Ch11Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch11Button.Text = 'Ch11';
            app.Ch11Button.Position = [11 190 50 22];

            % Create Ch12Button
            app.Ch12Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch12Button.Text = 'Ch12';
            app.Ch12Button.Position = [11 164 51 22];

            % Create Ch13Button
            app.Ch13Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch13Button.Text = 'Ch13';
            app.Ch13Button.Position = [11 138 51 22];

            % Create Ch14Button
            app.Ch14Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch14Button.Text = 'Ch14';
            app.Ch14Button.Position = [11 112 51 22];

            % Create Ch15Button
            app.Ch15Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch15Button.Text = 'Ch15';
            app.Ch15Button.Position = [11 86 51 22];

            % Create Ch16Button
            app.Ch16Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch16Button.Text = 'Ch16';
            app.Ch16Button.Position = [11 60 51 22];

            % Create Ch17Button
            app.Ch17Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch17Button.Text = {'Ch17'; ''};
            app.Ch17Button.Position = [212 455 58 22];

            % Create Ch18Button
            app.Ch18Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch18Button.Text = {'Ch18'; ''};
            app.Ch18Button.Position = [212 428 58 22];

            % Create Ch19Button
            app.Ch19Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch19Button.Text = {'Ch19'; ''};
            app.Ch19Button.Position = [212 401 65 22];

            % Create Ch20Button
            app.Ch20Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch20Button.Text = 'Ch20';
            app.Ch20Button.Position = [212 374 51 22];

            % Create Ch21Button
            app.Ch21Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch21Button.Text = 'Ch21';
            app.Ch21Button.Position = [212 347 51 22];

            % Create Ch22Button
            app.Ch22Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch22Button.Text = 'Ch22';
            app.Ch22Button.Position = [212 320 51 22];

            % Create Ch23Button
            app.Ch23Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch23Button.Text = 'Ch23';
            app.Ch23Button.Position = [212 294 51 22];

            % Create Ch24Button
            app.Ch24Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch24Button.Text = 'Ch24';
            app.Ch24Button.Position = [212 268 51 22];

            % Create Ch25Button
            app.Ch25Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch25Button.Text = 'Ch25';
            app.Ch25Button.Position = [212 242 51 22];

            % Create Ch26Button
            app.Ch26Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch26Button.Text = 'Ch26';
            app.Ch26Button.Position = [212 216 51 22];

            % Create Ch27Button
            app.Ch27Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch27Button.Text = 'Ch27';
            app.Ch27Button.Position = [212 190 51 22];

            % Create Ch28Button
            app.Ch28Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch28Button.Text = 'Ch28';
            app.Ch28Button.Position = [212 164 51 22];

            % Create Ch29Button
            app.Ch29Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch29Button.Text = 'Ch29';
            app.Ch29Button.Position = [212 138 51 22];

            % Create Ch30Button
            app.Ch30Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch30Button.Text = 'Ch30';
            app.Ch30Button.Position = [212 112 51 22];

            % Create Ch31Button
            app.Ch31Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch31Button.Text = 'Ch31';
            app.Ch31Button.Position = [212 86 51 22];

            % Create Ch32Button
            app.Ch32Button = uiradiobutton(app.UnitsButtonGroup);
            app.Ch32Button.Text = 'Ch32';
            app.Ch32Button.Position = [212 60 51 22];

            % Create EditField_1
            app.EditField_1 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_1.Position = [71 456 100 20];

            % Create EditField_2
            app.EditField_2 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_2.Position = [71 429 100 20];

            % Create EditField_3
            app.EditField_3 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_3.Position = [71 402 100 20];

            % Create EditField_4
            app.EditField_4 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_4.Position = [71 375 100 20];

            % Create EditField_5
            app.EditField_5 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_5.Position = [71 348 100 20];

            % Create EditField_6
            app.EditField_6 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_6.Position = [71 321 100 20];

            % Create EditField_7
            app.EditField_7 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_7.Position = [71 295 100 20];

            % Create EditField_8
            app.EditField_8 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_8.Position = [71 269 100 20];
            app.EditField_8.Value = ' ';

            % Create EditField_9
            app.EditField_9 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_9.Position = [71 243 100 20];

            % Create EditField_10
            app.EditField_10 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_10.Position = [71 217 100 20];

            % Create EditField_11
            app.EditField_11 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_11.Position = [71 191 100 20];

            % Create EditField_12
            app.EditField_12 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_12.Position = [71 165 100 20];

            % Create EditField_13
            app.EditField_13 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_13.Position = [71 139 100 20];

            % Create EditField_14
            app.EditField_14 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_14.Position = [71 113 100 20];

            % Create EditField_15
            app.EditField_15 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_15.Position = [71 87 100 20];

            % Create EditField_16
            app.EditField_16 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_16.Position = [71 61 100 20];

            % Create EditField_17
            app.EditField_17 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_17.Position = [279 456 100 20];

            % Create EditField_18
            app.EditField_18 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_18.Position = [279 429 100 20];

            % Create EditField_19
            app.EditField_19 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_19.Position = [279 402 100 20];

            % Create EditField_20
            app.EditField_20 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_20.Position = [279 375 100 20];

            % Create EditField_21
            app.EditField_21 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_21.Position = [279 348 100 20];

            % Create EditField_22
            app.EditField_22 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_22.Position = [279 321 100 20];

            % Create EditField_23
            app.EditField_23 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_23.Position = [279 295 100 20];

            % Create EditField_24
            app.EditField_24 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_24.Position = [279 269 100 20];

            % Create EditField_25
            app.EditField_25 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_25.Position = [279 243 100 20];

            % Create EditField_26
            app.EditField_26 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_26.Position = [279 217 100 20];

            % Create EditField_27
            app.EditField_27 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_27.Position = [279 191 100 20];

            % Create EditField_28
            app.EditField_28 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_28.Position = [279 165 100 20];

            % Create EditField_29
            app.EditField_29 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_29.Position = [279 139 100 20];

            % Create EditField_30
            app.EditField_30 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_30.Position = [279 113 100 20];

            % Create EditField_31
            app.EditField_31 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_31.Position = [279 87 100 20];

            % Create EditField_32
            app.EditField_32 = uieditfield(app.UnitsButtonGroup, 'text');
            app.EditField_32.Position = [279 61 100 20];

            % Create PolytrodesEditFieldLabel
            app.PolytrodesEditFieldLabel = uilabel(app.UnitsButtonGroup);
            app.PolytrodesEditFieldLabel.HorizontalAlignment = 'right';
            app.PolytrodesEditFieldLabel.Position = [11 21 64 22];
            app.PolytrodesEditFieldLabel.Text = 'Polytrodes';

            % Create PolytrodesEditField
            app.PolytrodesEditField = uieditfield(app.UnitsButtonGroup, 'text');
            app.PolytrodesEditField.Position = [82 23 93 20];

            % Create BuildrarrayButton
            app.BuildrarrayButton = uibutton(app.Panel, 'push');
            app.BuildrarrayButton.Position = [27 -148 100 22];
            app.BuildrarrayButton.Text = {'Build r array'; ''};

            % Create ANMEditFieldLabel
            app.ANMEditFieldLabel = uilabel(app.Panel);
            app.ANMEditFieldLabel.Position = [9 766 37 22];
            app.ANMEditFieldLabel.Text = 'ANM ';

            % Create ANMEditField
            app.ANMEditField = uieditfield(app.Panel, 'text');
            app.ANMEditField.Position = [45 766 50 22];

            % Create MEDfileLabel
            app.MEDfileLabel = uilabel(app.Panel);
            app.MEDfileLabel.Position = [148 615 244 22];
            app.MEDfileLabel.Text = {'MED file'; ''};

            % Create BpodfileLabel
            app.BpodfileLabel = uilabel(app.Panel);
            app.BpodfileLabel.Position = [148 581 244 22];
            app.BpodfileLabel.Text = {'Bpod file'; ''};

            % Create BuildButton
            app.BuildButton = uibutton(app.Panel, 'push');
            app.BuildButton.ButtonPushedFcn = createCallbackFcn(app, @BuildButtonPushed, true);
            app.BuildButton.FontSize = 15;
            app.BuildButton.Position = [245 735 70 52];
            app.BuildButton.Text = 'Build';

            % Create SegmentsDropDownLabel
            app.SegmentsDropDownLabel = uilabel(app.Panel);
            app.SegmentsDropDownLabel.HorizontalAlignment = 'right';
            app.SegmentsDropDownLabel.Position = [9 724 59 27];
            app.SegmentsDropDownLabel.Text = {'Segments'; ''; ''};

            % Create SegmentsDropDown
            app.SegmentsDropDown = uidropdown(app.Panel);
            app.SegmentsDropDown.DropDownOpeningFcn = createCallbackFcn(app, @SegmentsDropDownOpening, true);
            app.SegmentsDropDown.Position = [74 732 89 22];

            % Create ExperimenterEditFieldLabel
            app.ExperimenterEditFieldLabel = uilabel(app.Panel);
            app.ExperimenterEditFieldLabel.HorizontalAlignment = 'right';
            app.ExperimenterEditFieldLabel.Position = [103 767 77 22];
            app.ExperimenterEditFieldLabel.Text = 'Experimenter';

            % Create ExperimenterEditField
            app.ExperimenterEditField = uieditfield(app.Panel, 'text');
            app.ExperimenterEditField.Position = [184 765 50 22];

            % Create SaveGUIfigButton
            app.SaveGUIfigButton = uibutton(app.Panel, 'push');
            app.SaveGUIfigButton.ButtonPushedFcn = createCallbackFcn(app, @SaveGUIfigButtonPushed, true);
            app.SaveGUIfigButton.WordWrap = 'on';
            app.SaveGUIfigButton.FontSize = 15;
            app.SaveGUIfigButton.Position = [323 735 70 50];
            app.SaveGUIfigButton.Text = {'Save GUI fig'; ''};

            % Create CheckunitsButton
            app.CheckunitsButton = uibutton(app.Panel, 'push');
            app.CheckunitsButton.ButtonPushedFcn = createCallbackFcn(app, @CheckunitsButtonPushed, true);
            app.CheckunitsButton.Position = [397 764 100 25];
            app.CheckunitsButton.Text = 'Check units';

            % Create UnitsInCh
            app.UnitsInCh = uidropdown(app.Panel);
            app.UnitsInCh.Items = {'Unit 1'};
            app.UnitsInCh.ValueChangedFcn = createCallbackFcn(app, @UnitsInChValueChanged, true);
            app.UnitsInCh.Position = [397 732 100 25];
            app.UnitsInCh.Value = 'Unit 1';

            % Create PlotPSTHButton
            app.PlotPSTHButton = uibutton(app.Panel, 'push');
            app.PlotPSTHButton.ButtonPushedFcn = createCallbackFcn(app, @PlotPSTHButtonPushed, true);
            app.PlotPSTHButton.Position = [397 700 100 25];
            app.PlotPSTHButton.Text = 'Plot PSTH';

            % Create PlotAllPSTHsButton
            app.PlotAllPSTHsButton = uibutton(app.Panel, 'push');
            app.PlotAllPSTHsButton.ButtonPushedFcn = createCallbackFcn(app, @PlotAllPSTHsButtonPushed, true);
            app.PlotAllPSTHsButton.Position = [397 671 100 22];
            app.PlotAllPSTHsButton.Text = {'Plot All  PSTHs'; ''};

            % Create LoadButton
            app.LoadButton = uibutton(app.Panel, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.FontSize = 15;
            app.LoadButton.Position = [245 704 70 25];
            app.LoadButton.Text = 'Load';

            % Create PlotpopulationButton_2
            app.PlotpopulationButton_2 = uibutton(app.Panel, 'push');
            app.PlotpopulationButton_2.ButtonPushedFcn = createCallbackFcn(app, @PlotpopulationButton_2Pushed, true);
            app.PlotpopulationButton_2.Position = [397 639 100 25];
            app.PlotpopulationButton_2.Text = 'Plot population';

            % Create ProtocolDropDownLabel
            app.ProtocolDropDownLabel = uilabel(app.Panel);
            app.ProtocolDropDownLabel.HorizontalAlignment = 'right';
            app.ProtocolDropDownLabel.Position = [14 703 50 22];
            app.ProtocolDropDownLabel.Text = 'Protocol';

            % Create ProtocolDropDown
            app.ProtocolDropDown = uidropdown(app.Panel);
            app.ProtocolDropDown.Items = {'TwoFPs', 'Wait1', 'Wait2', 'Kornblum', ''};
            app.ProtocolDropDown.Position = [16 678 114 22];
            app.ProtocolDropDown.Value = 'TwoFPs';

            % Create mean_subCheckBox
            app.mean_subCheckBox = uicheckbox(app.Panel);
            app.mean_subCheckBox.Text = 'mean_sub';
            app.mean_subCheckBox.Position = [319 703 78 22];

            % Create Panel_2
            app.Panel_2 = uipanel(app.Panel);
            app.Panel_2.Position = [511 746 306 36];

            % Create PreEditFieldLabel
            app.PreEditFieldLabel = uilabel(app.Panel_2);
            app.PreEditFieldLabel.HorizontalAlignment = 'right';
            app.PreEditFieldLabel.Position = [5 7 25 22];
            app.PreEditFieldLabel.Text = 'Pre';

            % Create PreEditField
            app.PreEditField = uieditfield(app.Panel_2, 'numeric');
            app.PreEditField.Position = [36 7 53 22];
            app.PreEditField.Value = 5000;

            % Create PostEditFieldLabel
            app.PostEditFieldLabel = uilabel(app.Panel_2);
            app.PostEditFieldLabel.HorizontalAlignment = 'right';
            app.PostEditFieldLabel.Position = [97 7 30 22];
            app.PostEditFieldLabel.Text = 'Post';

            % Create PostEditField
            app.PostEditField = uieditfield(app.Panel_2, 'numeric');
            app.PostEditField.Position = [132 7 49 22];
            app.PostEditField.Value = 2000;

            % Create SpkmaxEditFieldLabel
            app.SpkmaxEditFieldLabel = uilabel(app.Panel_2);
            app.SpkmaxEditFieldLabel.HorizontalAlignment = 'right';
            app.SpkmaxEditFieldLabel.Position = [188 7 52 22];
            app.SpkmaxEditFieldLabel.Text = 'Spk max';

            % Create SpkmaxEditField
            app.SpkmaxEditField = uieditfield(app.Panel_2, 'numeric');
            app.SpkmaxEditField.Position = [252 6 37 22];
            app.SpkmaxEditField.Value = 40;

            % Create KornblumCheckBox
            app.KornblumCheckBox = uicheckbox(app.Panel);
            app.KornblumCheckBox.Text = 'Kornblum';
            app.KornblumCheckBox.Position = [173 733 73 22];

            % Create DIversionDropDownLabel
            app.DIversionDropDownLabel = uilabel(app.Panel);
            app.DIversionDropDownLabel.HorizontalAlignment = 'right';
            app.DIversionDropDownLabel.Position = [140 703 59 22];
            app.DIversionDropDownLabel.Text = 'DI version';

            % Create DIversionDropDown
            app.DIversionDropDown = uidropdown(app.Panel);
            app.DIversionDropDown.Items = {'Version4', 'Version5'};
            app.DIversionDropDown.ValueChangedFcn = createCallbackFcn(app, @DIversionDropDownValueChanged, true);
            app.DIversionDropDown.Position = [140 679 100 22];
            app.DIversionDropDown.Value = 'Version4';

            % Create BpodProtocolDropDownLabel
            app.BpodProtocolDropDownLabel = uilabel(app.Panel);
            app.BpodProtocolDropDownLabel.HorizontalAlignment = 'right';
            app.BpodProtocolDropDownLabel.Position = [16 648 81 22];
            app.BpodProtocolDropDownLabel.Text = 'Bpod Protocol';

            % Create BpodProtocolDropDown
            app.BpodProtocolDropDown = uidropdown(app.Panel);
            app.BpodProtocolDropDown.Items = {'OptoRecording', 'OptoRecordingMix'};
            app.BpodProtocolDropDown.Position = [131 648 135 22];
            app.BpodProtocolDropDown.Value = 'OptoRecording';

            % Create BlankoutEditFieldLabel
            app.BlankoutEditFieldLabel = uilabel(app.Panel);
            app.BlankoutEditFieldLabel.HorizontalAlignment = 'right';
            app.BlankoutEditFieldLabel.Position = [398 611 56 22];
            app.BlankoutEditFieldLabel.Text = 'Blank-out';

            % Create BlankoutEditField
            app.BlankoutEditField = uieditfield(app.Panel, 'text');
            app.BlankoutEditField.Position = [403 583 50 22];

            % Create EphysSegsEditFieldLabel
            app.EphysSegsEditFieldLabel = uilabel(app.Panel);
            app.EphysSegsEditFieldLabel.HorizontalAlignment = 'right';
            app.EphysSegsEditFieldLabel.Position = [471 611 70 22];
            app.EphysSegsEditFieldLabel.Text = 'Ephys Segs';

            % Create EphysSegsEditField
            app.EphysSegsEditField = uieditfield(app.Panel, 'text');
            app.EphysSegsEditField.Tooltip = {'if present, keep ephys segments . eg.. [0, 0, 1, 1] means keep data 003, and 004 '; ''};
            app.EphysSegsEditField.Position = [481 583 50 22];

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create Menu
            app.Menu = uimenu(app.ContextMenu);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.ContextMenu);
            app.Menu2.Text = 'Menu2';
            
            % Assign app.ContextMenu
            app.SegmentsDropDown.ContextMenu = app.ContextMenu;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = BuildR

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end