function EventOut = hbAlignMED2BR(EventOut, MEDdata, MEDProtocol, options)

% 19/Apr/2023, Hanbo Wang
% Integrate NAIVE stages, set MEDProtocol as necessary input

% 01/Oct/2022, Hanbo Wang
% To align MED with BR data in LeverPress & LeverRelease
% GoodRelease: MEDTTL recorded in BR, always 90ms later than
% LeverPress/Release induced tone signal
% 90ms = 100ms(MEDTTL latency in MED protocol) - 10ms(time resolution of LeverRelease)
% Timeline: LeverPress/Release --> 10ms --> Tone --> 90ms --> MEDTTL

% Fixed a bug to adopt for different versions of TrackMEDBehavior (YJN or WHB), CY
% Revised from @AlignMED2BRWait 3/3/2021 Jianing Yu
% EventOut comes from BlackRock's digital input
% bMED is the b array coming from MED data
% Time of some critical behavioral events (e.g., Trigger stimulus) needs to be mapped to EventOut
% Alignment is performed using press onset data
% Alignment of each trigger stimulus needs to be adjusted to the preceding press onset

arguments
    EventOut
    MEDdata
    MEDProtocol string {mustBeMember(MEDProtocol, ...
        ["AutoShaping", "LeverPress", "LeverRelease", ...
         "Wait1", "Wait2", "Wait", "2FPs", "3FPs"])} = "2FPs"
    options.durTone = 250
end

tPress_MED   = MEDdata.PressTime*1000;   % turn press time to ms
tRelease_MED = MEDdata.ReleaseTime*1000; % lever releases recorded in MED
tTone_MED    = MEDdata.TimeTone*1000;    % trigger time recorded in MED
Outcome_MED  = MEDdata.Outcome;
if isfield(MEDdata,'FPs')
    FP_MED = MEDdata.FPs;
elseif isfield(MEDdata,'FP')
    FP_MED = MEDdata.FP;
else
    error('Foreperiod data not found');
end

switch MEDProtocol

    case {"LeverPress", "LeverRelease"}

        % Load tTone from BR & MED data
        tTone_Ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'GoodRelease')} - 90;
        % find out the corresponding index of each ephys presses in MED
        % findseqmatchrev(seqmom, seqson, man, toprint, toprintname)
        idxMatched  = findseqmatchrev(tTone_MED, tTone_Ephys, 0, 0);
        tTone_Ephys = tTone_Ephys(~isnan(idxMatched));
        idxMatched  = idxMatched(~isnan(idxMatched));
        
        tTone_EphysMED = tTone_MED(idxMatched);    % this is the lever press time in MED during ephys recording
        EventOut.Onset{strcmp(EventOut.EventsLabels, 'GoodRelease')} = tTone_Ephys + 90;
        
        %% LeverPress/Release: compute press/release time
        tPress_Ephys   = zeros(length(tTone_Ephys), 1);
        tRelease_Ephys = zeros(length(tTone_Ephys), 1);
        for i = 1:length(tTone_Ephys)
            itTone_EphysMED = tTone_EphysMED(i); % Tone time of current ephys trial in MED
            % Find press and release time in MED
            itPress_MED   = tPress_MED(find(tPress_MED <= itTone_EphysMED, 1, 'last'));
            itRelease_MED = tRelease_MED(find(tRelease_MED+10 >= itTone_EphysMED, 1, 'first'));
            itTone_Ephys  = tTone_Ephys(i);
            tPress_Ephys(i)   = itTone_Ephys + itPress_MED   - itTone_EphysMED;
            tRelease_Ephys(i) = itTone_Ephys + itRelease_MED - itTone_EphysMED;
        end
        
        EventOut.FPEphys  = FP_MED(idxMatched);
        EventOut.OutcomeEphys = Outcome_MED(idxMatched);
        ha = figure(47); clf(ha, "reset");
        set(ha, 'name', 'Check MED BR Alignment', 'units', 'centimeters', ...
            'position', [2 2 24 15], 'color', 'w');
        subplot(2,1,1); hold on;
        plot(tTone_Ephys, 2, 'ko');
        if MEDProtocol == "LeverPress"
            line([tPress_Ephys tPress_Ephys], [1 3]', 'color', 'm');
            ylabel('Press');
        else
            line([tRelease_Ephys tRelease_Ephys], [1 3]', 'color', 'm');
            ylabel('Release');
        end
        set(gca, 'ylim', [0.8 3.2]);
        
        subplot(2,1,2);
        histogram(abs(tRelease_Ephys-tPress_Ephys));
        xlabel('Histogram of press duration');
        ylabel('Count');

    case {"Wait1", "Wait2", "Wait", "2FPs", "3FPs"}

        % Lever presses and releases recorded in blackrock
        tPress_Ephys   = EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')};
        tRelease_Ephys = EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')};
        
        % find out the corresponding index of each ephys presses in MED
        % findseqmatchrev(seqmom, seqson, man, toprint, toprintname)
        idxMatched     = findseqmatchrev(tPress_MED, tPress_Ephys, 0, 0);
        
        tPress_Ephys   = tPress_Ephys(~isnan(idxMatched));
        tRelease_Ephys = tRelease_Ephys(~isnan(idxMatched));
        idxMatched     = idxMatched(~isnan(idxMatched));
        
        tPress_EphysMED   = tPress_MED(idxMatched);    % this is the lever press time in MED during ephys recording
        tRelease_EphysMED = tRelease_MED(idxMatched);  % index should be the same for press and release
        EventOut.FPEphys  = FP_MED(idxMatched);
        EventOut.OutcomeEphys = Outcome_MED(idxMatched);

        % Get mapped lever release time
        tRelease_EphysMapped = zeros(length(tRelease_Ephys),1);
        for i = 1:length(tRelease_Ephys)
            tRelease_EphysMapped(i) = tPress_Ephys(i) + tRelease_EphysMED(i) - tPress_EphysMED(i);
        end
        
        % To find tone time in Blackrock:
        %   idxToneEphys: use (Correct + Late) index get trials with tone onset
        %   then get press time of these trials in Ephys and in MED(EphysMED)
        %   tPress_Ephys + tTone_MED - tPress_MED
        idxToneEphys = find(EventOut.OutcomeEphys=="Correct" | EventOut.OutcomeEphys=="Late");
        tPress_Tone_Ephys    = tPress_Ephys(idxToneEphys);
        tPress_Tone_EphysMED = tPress_EphysMED(idxToneEphys);
        tTone_Ephys = zeros(length(tPress_Tone_Ephys), 1);
        FPsMapped = zeros(length(tPress_Tone_Ephys), 1);
        for i = 1:length(tPress_Tone_Ephys)
            itPress_Tone_EphysMED = tPress_Tone_EphysMED(i);
            itTone_EphysMED = tTone_MED(find(tTone_MED >= itPress_Tone_EphysMED, 1, 'first'));
            itPress_Tone_Ephys = tPress_Tone_Ephys(i);  % press time of trial with tone onset
            tTone_Ephys(i) = itPress_Tone_Ephys + itTone_EphysMED - itPress_Tone_EphysMED;
            FPsMapped(i) = tTone_Ephys(i) - itPress_Tone_Ephys;
        end
        
        ha = figure(47); clf(ha, "reset");
        set(ha, 'name', 'Check MED BR Alignment', 'units', 'centimeters', ...
            'position', [2 2 24 15], 'color', 'w');
        subplot(2,2,[1 2]); hold on;
        plot(tRelease_Ephys, 2, 'ko');
        line([tRelease_EphysMapped tRelease_EphysMapped], [1 3]', 'color', 'm');
        set(gca, 'ylim', [0.8 3.2]);
        ylabel('Release');
        
        subplot(2,2,3);
        histogram(abs(tRelease_Ephys-tRelease_EphysMapped));
        xlabel('Time difference between Blackrock release and MED release');
        ylabel('Count');
        
        subplot(2,2,4);
        plot(FPsMapped, 'ro');
        ylabel('FPs of all trigger trials');
        
end

% Here we don't update release time by MED data (won't use tRelease_EphysMapped)
% just remove unmatched trials
EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')}  = tPress_Ephys;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')} = tRelease_Ephys;

if any(strcmp(EventOut.EventsLabels, 'Trigger'))
    EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')}  = tTone_Ephys;
    EventOut.Offset{strcmp(EventOut.EventsLabels, 'Trigger')} = tTone_Ephys + options.durTone;
else
    EventOut.EventsLabels{end+1} = 'Trigger';
    EventOut.Onset{end+1}  = tTone_Ephys;
    EventOut.Offset{end+1} = tTone_Ephys + options.durTone;
end

end