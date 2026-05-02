%% Load data files
% load behavior class file
beh_file = dir("./*BehSessionClass*.mat");
if isempty(beh_file)
    error("did not find a behavior class file.");
elseif length(beh_file)>1
    error("found more than one behavior class file.");
end
load(beh_file.name);
Beh = obj; clear obj
BehTable = Beh.BehavTable;

% load event mark file
if exist('./EventOut.mat', 'file')
    load("./EventOut.mat");
else
    error("did not find a event mark file.")
end

%%
disp(EventOut.EventsLabels);

[IndCentIn, FigAlignCentIn] = findseqmatchrev(1000*BehTable.TrialCentInTime, EventOut.Onset{1}, 0, 0, '', 5);
saveas(FigAlignCentIn, "FigAlignCentIn.png");

[IndChoiceIn, FigAlignChoiceIn] = findseqmatchrev(1000*(BehTable.TrialStartTime+BehTable.ChoicePokeTime), EventOut.Onset{2}, 0, 0, '', 5);
saveas(FigAlignChoiceIn, "FigAlignChoiceIn.png");

close(38);

%%

