function [bEvent, pEvent, bInt, pInt, str] = extract_event_and_interaction(mdl)

fe = mdl.Coefficients;  % table with Estimate, SE, DF, tStat, pValue

% robustly find rows by name
rn = string(fe.Properties.RowNames);

iEvent = find(rn == "Event_Post", 1);
iInt   = find(rn == "RewardType_Omitted:Event_Post", 1);

if isempty(iEvent) || isempty(iInt)
    error("Could not find Event_Post and/or RewardType_Omitted:Event_Post in mdl.Coefficients.Name");
end

bEvent = fe.Estimate(iEvent);
pEvent = fe.pValue(iEvent);

bInt   = fe.Estimate(iInt);
pInt   = fe.pValue(iInt);

% nice compact string (two lines)
str = sprintf(['\\beta_{poke}=%.2f, p=%s\n' ...
               'Omitted:\n \\Delta\\beta=%.2f, p = %s'], ...
               bEvent, fmt_p(pEvent), bInt, fmt_p(pInt));
end

function s = fmt_p(p)
if p < 1e-3
    s = sprintf('%.1g', p);   % e.g. 2.6e-04
else
    s = sprintf('%.3f', p);
end
end
