function EphysTable = getEphysTable(r)

rb = r.Behavior;
EphysTable = r.BehaviorClass.BehavTable(:, ["Subject", "Session", "Trials", "Stage", "FP", "PortCorrect", "PortChosen", "Cued", "Outcome"]);
EphysTable = EphysTable(ismember(EphysTable.Trials, rb.TrialID), :);

t_centin  = rb.EventTimings(rb.EventMarkers==find(strcmp(rb.Labels, 'PokeCentIn')));
t_centout = rb.EventTimings(rb.EventMarkers==find(strcmp(rb.Labels, 'PokeCentOut')));
t_trigger = rb.EventTimings(rb.EventMarkers==find(strcmp(rb.Labels, 'Trigger')));
t_choice  = rb.EventTimings(rb.EventMarkers==find(strcmp(rb.Labels, 'PokeChoiceIn')));
t_initin  = rb.EventTimings(rb.EventMarkers==find(strcmp(rb.Labels, 'PokeInitIn')));
t_initout = rb.EventTimings(rb.EventMarkers==find(strcmp(rb.Labels, 'PokeInitOut')));

EphysTable.tInitIn  = t_initin;
EphysTable.tInitOut = t_initout;
EphysTable.tCentIn  = t_centin;
EphysTable.tCentOut = t_centout;

EphysTable.tTrigger = nan(length(t_centin), 1);
EphysTable.tChoice  = nan(length(t_centin), 1);
for i = 1:length(t_centin)
    if i < length(t_centin)
        id_trigger = find(t_trigger>t_centin(i) & t_trigger<t_centin(i+1));
        id_choice  = find(t_choice>t_centin(i) & t_choice<t_centin(i+1));
    else
        id_trigger = find(t_trigger>t_centin(i));
        id_choice  = find(t_choice>t_centin(i));
    end
    if ~isempty(id_trigger)
        EphysTable.tTrigger(i) = t_trigger(id_trigger);
    end
    if ~isempty(id_choice)
        EphysTable.tChoice(i) = t_choice(id_choice);
    end
end

EphysTable.FP(EphysTable.FP==-1) = Inf;
EphysTable.ST = EphysTable.tCentIn - EphysTable.tInitOut;
EphysTable.HD = EphysTable.tCentOut - EphysTable.tCentIn;
EphysTable.RT = EphysTable.tCentOut - EphysTable.tTrigger;
EphysTable.MT = EphysTable.tChoice - EphysTable.tCentOut;

% r.EphysTable = EphysTable;
% save(sprintf('RTarray_%s_%s.mat', r.BehaviorClass.Subject, r.BehaviorClass.Session), "r");

end