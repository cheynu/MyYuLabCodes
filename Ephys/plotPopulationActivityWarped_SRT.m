function plotPopulationActivityWarped_SRT(r,opts)
%% Plot population PSTH of MixedFPsSRT task (only correct trials)
% Revised from Yue Huang, 2025.3.14 Yu Chen
arguments
    r
    opts.t_pre = -2000 % ms
    opts.t_press = 0 % ms
    opts.t_trigger = 1500 % ms
    opts.t_post_reward = 2000
    opts.gaussian_kernel = 50
    opts.UnitsFilter {mustBeMember(opts.UnitsFilter,["All","Single","Multi"])} = "All"
    opts.SaveInterVars = true
    opts.FigSavePath = 'Fig'
    opts.PlotFromInterVars = false
end
t_pre = opts.t_pre;
t_press = opts.t_press;
t_trigger = opts.t_trigger;
t_post_reward = opts.t_post_reward;
gaussian_kernel = opts.gaussian_kernel;
switch opts.UnitsFilter
    case "All"
        unitFilter = [];
    case "Single"
        unitFilter = 1;
    case "Multi"
        unitFilter = 2;
end
if isempty(unitFilter)
    units_of_interest = 1:size(r.Units.SpikeNotes,1);
else
    units_of_interest = find(r.Units.SpikeNotes(:,3)==unitFilter);
end
units_of_interest_ch = r.Units.SpikeNotes(units_of_interest,1:3);
ifSaveInterVars = opts.SaveInterVars;
pathFig = opts.FigSavePath;
ifReProcess = ~opts.PlotFromInterVars;

if ifReProcess

else
    dataWarped = dir('PopulationDataWarped*.mat');
    load(dataWarped.name);
end

end

