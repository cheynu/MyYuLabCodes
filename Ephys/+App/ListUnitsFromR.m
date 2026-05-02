function ListUnitsFromR(r)
% product a ListUnitsSorted.cvs table from r
% so that 'Autofill' can read the unit information
r_name = Spikes.r_name;
if ~isempty(r_name)
    load(r_name);
else
    error('Cannot find r')
end;
spk_notes = r.Units.SpikeNotes;
n_unit = size(spk_notes, 1);
ch               =          zeros(n_unit, 1);
units           =          zeros(n_unit, 1);
unit_types   =          cell(n_unit, 1);
for i =1:n_unit
    ch(i) = spk_notes(i, 1);
    units(i) = spk_notes(i, 2);
    if spk_notes(i, 3)==1
        unit_types{i} = 's';
    else
        unit_types{i} = 'm';
    end;
end;
tab = table(ch, units, unit_types, 'VariableNames',{'Channels', 'Units', 'UnitTypes'});
aGoodName = 'ListUnitsSorted.csv';
writetable(tab, aGoodName)
disp('Done making table')