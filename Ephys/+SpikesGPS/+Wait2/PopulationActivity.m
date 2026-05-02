function PopOut = PopulationActivity(r, varargin)

% 5/13/2023 Jianing Yu
% Build upon SRTSpikesPopulation
% Since we add PSTH to r, we will just use previously computed results to
% build Population activity. 
% we avoid re-compute the same stuff. 

% % if nargin<1
% %     load(Spikes.r_name)
% % end

Units = r.Units.SpikeNotes;
% Extract these event-related activity
[nFP, nPort] = size(r.PSTH.PSTHs(1).CentIn);
% nFP = length(r.BehaviorClass.TargetFP);
% nPort = length(r.BehaviorClass.Ports);

%
PSTH_CentIn        = cell(nFP, nPort); % one for short FP, one for long FP
PSTH_CentInZ       = cell(nFP, nPort); % one for short FP, one for long FP 
PSTH_CentInStat    = cell(nFP, nPort); % this gives the statistics of press

PSTH_CentInAll     = []; % merge short and long FPs
PSTH_CentInAllZ    = []; % one for short FP, one for long FP 
PSTH_CentInAllStat = [];

PSTH_CentOut        = cell(nFP, nPort);
PSTH_CentOutZ       = cell(nFP, nPort);
PSTH_CentOutStat    = cell(nFP, nPort); % this gives the statistics of release

PSTH_CentOutAll     = []; % merge short and long FPs
PSTH_CentOutAllZ    = []; % one for short FP, one for long FP 
PSTH_CentOutAllStat = [];

PSTH_Reward     = cell(nFP, nPort);
PSTH_RewardZ    = cell(nFP, nPort);
PSTH_RewardStat = cell(nFP, nPort); % this gives the statistics of release

PSTH_Trigger     = cell(nFP, nPort);
PSTH_TriggerZ    = cell(nFP, nPort);
PSTH_TriggerStat = cell(nFP, nPort); % this gives the statistics of trigger

if ~isfield(r, 'PSTH')
    error('Compute PSTH first. Run " >>SRTSpikes(r, []);" ')
end

n_unit = length(r.PSTH.PSTHs);
t_baseline = [-5000 -1000]; % from -5000 to -500 ms is considered to be the baseline. 
% spikes during this period will be used to normalize the neural activity(z score). 
% if the activity is extremely sparse during this period (e..g, avg rate <
% 1 Hz), we will then use the whole press_all activity to compute z score. 

for i = 1:n_unit
    PSTH_baseline = [];
    if i==1 % first row for time info
        PSTH_CentInAll(1, :)  = r.PSTH.PSTHs(i).CentInAll{2};
        PSTH_CentInAllZ(1, :) = r.PSTH.PSTHs(i).CentInAll{2};
    end
    PSTH_CentInAll = [PSTH_CentInAll; r.PSTH.PSTHs(i).CentInAll{1}];
    tspkmat_centinall = r.PSTH.PSTHs(i).CentInAll{4};
    trialspxmat_centinall = r.PSTH.PSTHs(i).CentInAll{3};

    StatOut = ExamineTaskResponsive(tspkmat_centinall, trialspxmat_centinall);
    StatOut.CellIndx = r.Units.SpikeNotes(i, :);
    PSTH_CentInAllStat.StatOut(i) = StatOut;
    PSTH_Trials = zeros(size(r.PSTH.PSTHs(i).CentIn));

    for jfp = 1:nFP
        for kport = 1:nPort
            if i==1 % first row for time info
                PSTH_CentIn{jfp, kport}(1, :)   = r.PSTH.PSTHs(1).CentIn{jfp, kport}{2};
                PSTH_CentInZ{jfp, kport}(1, :)  = r.PSTH.PSTHs(1).CentIn{jfp, kport}{2};
                PSTH_CentOut{jfp, kport}(1, :)  = r.PSTH.PSTHs(1).CentOut{jfp, kport}{2};
                PSTH_CentOutZ{jfp, kport}(1, :) = r.PSTH.PSTHs(1).CentOut{jfp, kport}{2};
                PSTH_Trigger{jfp, kport}(1, :)  = r.PSTH.PSTHs(1).Triggers{jfp, kport}{2};
                PSTH_TriggerZ{jfp, kport}(1, :) = r.PSTH.PSTHs(1).Triggers{jfp, kport}{2};
                PSTH_Reward{jfp, kport}(1, :)   = r.PSTH.PSTHs(1).RewardChoice{jfp, kport}{2};
                PSTH_RewardZ{jfp, kport}(1, :)  = r.PSTH.PSTHs(1).RewardChoice{jfp, kport}{2};
            end

            % CentIn
            PSTH_CentIn{jfp, kport} = [PSTH_CentIn{jfp, kport};  r.PSTH.PSTHs(i).CentIn{jfp, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).CentIn{jfp, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).CentIn{jfp, kport}{3};

            % restricting activity to a relatively narrow window.
            tCentInWin = [-2500 1500];
            indWin = find(tspkmat>=tCentInWin(1) & tspkmat<= tCentInWin(2));
            tspkmat = tspkmat(indWin);
            trialspxmat = trialspxmat(indWin, :);

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx = r.Units.SpikeNotes(i, :);
            PSTH_CentInStat{jfp, kport}.StatOut(i) = StatOut;
            PSTH_Trials(jfp, kport) = size(trialspxmat, 2);
            PSTH_baseline = [PSTH_baseline r.PSTH.PSTHs(i).CentIn{jfp, kport}{1}];

            % CentOut
            PSTH_CentOut{jfp, kport} = [PSTH_CentOut{jfp, kport};  r.PSTH.PSTHs(i).CentOut{jfp, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).CentOut{jfp, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).CentOut{jfp, kport}{3};

            % restricting activity to a relatively narrow window.
            tCentOutWin = [-500 1000];
            indWin = find(tspkmat>=tCentOutWin(1) & tspkmat<= tCentOutWin(2));
            tspkmat = tspkmat(indWin);
            trialspxmat = trialspxmat(indWin, :);

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
            PSTH_CentOutStat{jfp, kport}.StatOut(i) = StatOut;
            PSTH_baseline = [PSTH_baseline r.PSTH.PSTHs(i).CentOut{jfp, kport}{1}];

            % Trigger
            PSTH_Trigger{jfp, kport} = [PSTH_Trigger{jfp, kport}; r.PSTH.PSTHs(i).Triggers{jfp, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).Triggers{jfp, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).Triggers{jfp, kport}{3};

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx = r.Units.SpikeNotes(i, :);
            PSTH_TriggerStat{jfp, kport}.StatOut(i) =  StatOut;

            % Reward
            PSTH_Reward{jfp, kport} = [PSTH_Reward{jfp, kport};  r.PSTH.PSTHs(i).RewardChoice{jfp, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).RewardChoice{jfp, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).RewardChoice{jfp, kport}{3};

            % restricting activity to a relatively narrow window.
            tRewardWin = [-1000 1000];
            indWin = find(tspkmat>=tRewardWin(1) & tspkmat<= tRewardWin(2));
            tspkmat = tspkmat(indWin);
            trialspxmat = trialspxmat(indWin, :);

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
            PSTH_RewardStat{jfp, kport}.StatOut(i) =  StatOut;
            PSTH_baseline = [PSTH_baseline  r.PSTH.PSTHs(i).RewardChoice{jfp, kport}{1}];

            % compute z
            mean_baseline = mean(PSTH_baseline, 'omitnan');
            sd_baseline   = std(PSTH_baseline, 'omitnan');
            PSTH_CentInZ{jfp, kport}  = [PSTH_CentInZ{jfp, kport}; (r.PSTH.PSTHs(i).CentIn{jfp, kport}{1}-mean_baseline)/sd_baseline];
            PSTH_CentOutZ{jfp, kport} = [PSTH_CentOutZ{jfp, kport}; (r.PSTH.PSTHs(i).CentOut{jfp, kport}{1}-mean_baseline)/sd_baseline];
            PSTH_TriggerZ{jfp, kport} = [PSTH_TriggerZ{jfp, kport}; (r.PSTH.PSTHs(i).Triggers{jfp, kport}{1}-mean_baseline)/sd_baseline];
            PSTH_RewardZ{jfp, kport}  = [PSTH_RewardZ{jfp, kport}; (r.PSTH.PSTHs(i).RewardChoice{jfp, kport}{1}-mean_baseline)/sd_baseline];
        end
    end
end

PopOut.Name       = r.BehaviorClass.Subject;
PopOut.ImplantLateral = r.ImplantLateral;
PopOut.FPs        = r.BehaviorClass.TargetFP(1:nFP);
PopOut.Ports      = r.BehaviorClass.Ports;
PopOut.Trials     = PSTH_Trials;
PopOut.Session    = r.BehaviorClass.Session;
PopOut.Date       = strrep(r.Meta(1).DateTime(1:11), '-','_');
PopOut.Units      = Units;
PopOut.CentIn     = PSTH_CentIn;
PopOut.CentInZ    = PSTH_CentInZ;
PopOut.CentInStat = PSTH_CentInStat;

PopOut.CentInAll     = PSTH_CentInAll;
PopOut.CentInAllZ    = PSTH_CentInAllZ;
PopOut.CentInAllStat = PSTH_CentInAllStat;

PopOut.CentOut     = PSTH_CentOut;
PopOut.CentOutZ    = PSTH_CentOutZ;
PopOut.CentOutStat = PSTH_CentOutStat;

PopOut.CentOutAll     = PSTH_CentOutAll;
PopOut.CentOutAllZ    = PSTH_CentOutAllZ;
PopOut.CentOutAllStat = PSTH_CentOutAllStat;

PopOut.Reward     = PSTH_Reward;
PopOut.RewardZ    = PSTH_RewardZ;
PopOut.RewardStat = PSTH_RewardStat;

PopOut.Trigger     = PSTH_Trigger;
PopOut.TriggerZ    = PSTH_TriggerZ;
PopOut.TriggerStat = PSTH_TriggerStat;

[PopOut.IndSort, PopOut.IndUnmodulated] = SpikesGPS.SRT.RankActivityFlat(PopOut);

PopOut.IndSort = SpikesGPS.SRT.VisualizePopPSTH(PopOut, 'Each');
SpikesGPS.SRT.VisualizePopPSTH(PopOut, 'Ipsi');
SpikesGPS.SRT.VisualizePopPSTH(PopOut, 'Contra');

r.PopPSTH = PopOut;
r_name = 'RTarray_'+r.PSTH.PSTHs(1).ANM_Session{1}+'_'+strrep(r.PSTH.PSTHs(1).ANM_Session{2}, '_', '')+'.mat';
save(r_name, 'r');
% Save a copy of PSTHOut to a collector folder
tosavename = 'PopOut_'+r.PSTH.PSTHs(1).ANM_Session{1}+'_'+strrep(r.PSTH.PSTHs(1).ANM_Session{2}, '_', '')+'.mat';
save(tosavename, 'PopOut');

% thisFolder = fullfile(findonedrive, '00_Work' , '03_Projects', '05_Physiology', 'Data', 'PopulationPSTH', r.PSTH.PSTHs(1).ANM_Session{1});
% if ~exist(thisFolder, 'dir')
%     mkdir(thisFolder)
% end
% disp('##########  copying PopOut ########## ')
% tic
% copyfile(tosavename, thisFolder)
% toc