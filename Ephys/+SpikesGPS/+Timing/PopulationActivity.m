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
[nCue, nPort] = size(r.PSTH.PSTHs(1).CentIn);
% nFP = length(r.BehaviorClass.TargetFP);
% nPort = length(r.BehaviorClass.Ports);

%
PSTH_CentIn     = cell(nCue, nPort); % one for short FP, one for long FP
PSTH_CentInZ    = cell(nCue, nPort); % one for short FP, one for long FP 
PSTH_CentInStat = cell(nCue, nPort); % this gives the statistics of press

PSTH_CentInAll     = []; % merge short and long FPs
PSTH_CentInAllZ    = []; % one for short FP, one for long FP 
PSTH_CentInAllStat = [];

PSTH_CentOut     = cell(nCue, nPort);
PSTH_CentOutZ    = cell(nCue, nPort);
PSTH_CentOutStat = cell(nCue, nPort); % this gives the statistics of release

PSTH_CentOutAll     = []; % merge short and long FPs
PSTH_CentOutAllZ    = []; % one for short FP, one for long FP 
PSTH_CentOutAllStat = [];

PSTH_Reward     = cell(nCue, nPort);
PSTH_RewardZ    = cell(nCue, nPort);
PSTH_RewardStat = cell(nCue, nPort); % this gives the statistics of release

PSTH_Trigger     = cell(nCue, nPort);
PSTH_TriggerZ    = cell(nCue, nPort);
PSTH_TriggerStat = cell(nCue, nPort); % this gives the statistics of trigger

if ~isfield(r, 'PSTH')
    error('Compute PSTH first. Run " >>SRTSpikes(r, []);" ')
end

n_unit = length(r.PSTH.PSTHs);

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

    for jcue = 1:nCue
        for kport = 1:nPort
            if i==1 % first row for time info
                PSTH_CentIn{jcue, kport}(1, :)   = r.PSTH.PSTHs(1).CentIn{jcue, kport}{2};
                PSTH_CentInZ{jcue, kport}(1, :)  = r.PSTH.PSTHs(1).CentIn{jcue, kport}{2};
                PSTH_CentOut{jcue, kport}(1, :)  = r.PSTH.PSTHs(1).CentOut{jcue, kport}{2};
                PSTH_CentOutZ{jcue, kport}(1, :) = r.PSTH.PSTHs(1).CentOut{jcue, kport}{2};
                PSTH_Trigger{jcue, kport}(1, :)  = r.PSTH.PSTHs(1).Triggers{jcue, kport}{2};
                PSTH_TriggerZ{jcue, kport}(1, :) = r.PSTH.PSTHs(1).Triggers{jcue, kport}{2};
                PSTH_Reward{jcue, kport}(1, :)   = r.PSTH.PSTHs(1).RewardChoice{jcue, kport}{2};
                PSTH_RewardZ{jcue, kport}(1, :)  = r.PSTH.PSTHs(1).RewardChoice{jcue, kport}{2};
            end

            % CentIn
            PSTH_CentIn{jcue, kport} = [PSTH_CentIn{jcue, kport};  r.PSTH.PSTHs(i).CentIn{jcue, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).CentIn{jcue, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).CentIn{jcue, kport}{3};

            % restricting activity to a relatively narrow window.
            tCentInWin = [-2500 1500];
            indWin = find(tspkmat>=tCentInWin(1) & tspkmat<= tCentInWin(2));
            tspkmat = tspkmat(indWin);
            trialspxmat = trialspxmat(indWin, :);

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx = r.Units.SpikeNotes(i, :);
            PSTH_CentInStat{jcue, kport}.StatOut(i) = StatOut;
            PSTH_Trials(jcue, kport) = size(trialspxmat, 2);
            PSTH_baseline = [PSTH_baseline r.PSTH.PSTHs(i).CentIn{jcue, kport}{1}];

            % CentOut
            PSTH_CentOut{jcue, kport} = [PSTH_CentOut{jcue, kport};  r.PSTH.PSTHs(i).CentOut{jcue, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).CentOut{jcue, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).CentOut{jcue, kport}{3};

            % restricting activity to a relatively narrow window.
            tCentOutWin = [-500 1000];
            indWin = find(tspkmat>=tCentOutWin(1) & tspkmat<= tCentOutWin(2));
            tspkmat = tspkmat(indWin);
            trialspxmat = trialspxmat(indWin, :);

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
            PSTH_CentOutStat{jcue, kport}.StatOut(i) = StatOut;
            PSTH_baseline = [PSTH_baseline r.PSTH.PSTHs(i).CentOut{jcue, kport}{1}];

            % Trigger
            PSTH_Trigger{jcue, kport} = [PSTH_Trigger{jcue, kport}; r.PSTH.PSTHs(i).Triggers{jcue, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).Triggers{jcue, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).Triggers{jcue, kport}{3};

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx = r.Units.SpikeNotes(i, :);
            PSTH_TriggerStat{jcue, kport}.StatOut(i) =  StatOut;

            % Reward
            PSTH_Reward{jcue, kport} = [PSTH_Reward{jcue, kport};  r.PSTH.PSTHs(i).RewardChoice{jcue, kport}{1}];
            tspkmat     = r.PSTH.PSTHs(i).RewardChoice{jcue, kport}{4};
            trialspxmat = r.PSTH.PSTHs(i).RewardChoice{jcue, kport}{3};

            % restricting activity to a relatively narrow window.
            tRewardWin = [-1000 1000];
            indWin = find(tspkmat>=tRewardWin(1) & tspkmat<= tRewardWin(2));
            tspkmat = tspkmat(indWin);
            trialspxmat = trialspxmat(indWin, :);

            StatOut = ExamineTaskResponsive(tspkmat, trialspxmat);
            StatOut.CellIndx =  r.Units.SpikeNotes(i, :);
            PSTH_RewardStat{jcue, kport}.StatOut(i) =  StatOut;
            PSTH_baseline = [PSTH_baseline r.PSTH.PSTHs(i).RewardChoice{jcue, kport}{1}];

            % compute z
            mean_baseline = mean(PSTH_baseline, 'omitnan');
            sd_baseline   = std(PSTH_baseline, 'omitnan');
            PSTH_CentInZ{jcue, kport}  = [PSTH_CentInZ{jcue, kport}; (r.PSTH.PSTHs(i).CentIn{jcue, kport}{1}-mean_baseline)/sd_baseline];
            PSTH_CentOutZ{jcue, kport} = [PSTH_CentOutZ{jcue, kport}; (r.PSTH.PSTHs(i).CentOut{jcue, kport}{1}-mean_baseline)/sd_baseline];
            PSTH_TriggerZ{jcue, kport} = [PSTH_TriggerZ{jcue, kport}; (r.PSTH.PSTHs(i).Triggers{jcue, kport}{1}-mean_baseline)/sd_baseline];
            PSTH_RewardZ{jcue, kport}  = [PSTH_RewardZ{jcue, kport}; (r.PSTH.PSTHs(i).RewardChoice{jcue, kport}{1}-mean_baseline)/sd_baseline];

            PSTH_CentInZ{jcue, kport}(isnan(PSTH_CentInZ{jcue, kport}) | isinf(PSTH_CentInZ{jcue, kport}))    = 0;
            PSTH_CentOutZ{jcue, kport}(isnan(PSTH_CentOutZ{jcue, kport}) | isinf(PSTH_CentOutZ{jcue, kport})) = 0;
            PSTH_TriggerZ{jcue, kport}(isnan(PSTH_TriggerZ{jcue, kport}) | isinf(PSTH_TriggerZ{jcue, kport})) = 0;
            PSTH_RewardZ{jcue, kport}(isnan(PSTH_RewardZ{jcue, kport}) | isinf(PSTH_RewardZ{jcue, kport}))    = 0;
        end
    end
end

PopOut.Name       = r.BehaviorClass.Subject;
PopOut.ImplantLateral = r.ImplantLateral;
PopOut.FP         = r.BehaviorClass.TargetFP;
PopOut.CueUncue   = r.BehaviorClass.CueUncue;
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