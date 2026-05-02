function EventOut = hbAlignMED2BRbyTrigger(EventOut, MEDdata)

% 04/Jul/2023, Hanbo Wang
% Align MED to BR data by trigger signals (to deal with "ephys-press-error")

arguments
    EventOut
    MEDdata
end

tPress_MED   = MEDdata.PressTime*1000;   % turn press time to ms
tRelease_MED = MEDdata.ReleaseTime*1000; % lever releases recorded in MED
tTone_MED    = MEDdata.TimeTone*1000;    % trigger time recorded in MED

tTone_Ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'Trigger')};
% find out the corresponding index of each ephys presses in MED
% findseqmatchrev(seqmom, seqson, man, toprint, toprintname)
idxMatched  = findseqmatchrev(tTone_MED, tTone_Ephys, 0, 0);
tTone_Ephys = tTone_Ephys(~isnan(idxMatched));
idxMatched  = idxMatched(~isnan(idxMatched));

tTone_EphysMED = tTone_MED(idxMatched);    % this is the lever press time in MED during ephys recording
        
%% LeverPress/Release: compute press/release time
tPress_Ephys   = [];
tRelease_Ephys = [];
for i = 1:length(tTone_Ephys)
    itTone_EphysMED = tTone_EphysMED(i); % Tone time of current ephys trial in MED
    itTone_Ephys    = tTone_Ephys(i);
    if i == 1 % get press before the first tone
        idx = find(tPress_MED <= itTone_EphysMED, 1, 'last');
        itPress_MED   = tPress_MED(idx);
        itRelease_MED = [];
    else % get presses and releases between itones
        iitTone_EphysMED = tTone_EphysMED(i-1);
        idx = tPress_MED <= itTone_EphysMED & tPress_MED > iitTone_EphysMED;
        if any(idx)
            itPress_MED   = tPress_MED(idx);
            itRelease_MED = tRelease_MED(tRelease_MED >= iitTone_EphysMED & tRelease_MED < itTone_EphysMED);
        else
            itPress_MED = []; itRelease_MED = [];
        end
        if i == length(tTone_Ephys)
            itRelease_MED = [itRelease_MED tRelease_MED(find(tRelease_MED >= itTone_EphysMED, 1, 'first'))];
        end
    end
    % Find press and release time in MED
    tPress_Ephys   = [tPress_Ephys   itTone_Ephys-itTone_EphysMED+itPress_MED];
    tRelease_Ephys = [tRelease_Ephys itTone_Ephys-itTone_EphysMED+itRelease_MED];
end
tPress_Ephys = tPress_Ephys';
tRelease_Ephys = tRelease_Ephys';
% EventOut.FPEphys = FP_Ephys;
% EventOut.OutcomeEphys = Outcome_Ephys;
EventOut.Onset{strcmp(EventOut.EventsLabels, 'LeverPress')}  = tPress_Ephys;
EventOut.Offset{strcmp(EventOut.EventsLabels, 'LeverPress')} = tRelease_Ephys;

end