classdef BehaviorSRT_MED < BehaviorSRT
    % Hanbo Wang, Jan 2024
    % revised from @BehaviorMED by Yu Chen, Apr 2023
    % Inherit from BehaviorSRT class
    % Data calculated by BehaviorClass (by Jianing Yu)
    
    properties
        RawData
    end
    
    methods
        function obj = BehaviorSRT_MED(medfile, bpodfile, options)
            %BEHAVIORMED 构造此类的实例
            arguments
                medfile char {mustBeFile}
                bpodfile = [] % filename or SessionData struct
                options.Task = ""
            end

            % pre-process by BehaviorClass of JianingYu
            [b,bc] = TrackMEDBehavior(medfile);

            % Assignment
            % basic information
            data = struct;
            data.Subject = string(bc.Subject);
            data.Task = string(options.Task);
            data.Experiment = string(b.Metadata.Experiment);
            data.Date = str2double(bc.Date);
            data.DateTime = datetime([b.Metadata.Date 'T' b.Metadata.StartTime],'InputFormat','yyyyMMdd''T''HH:mm:ss');
            isWait = 0;
            switch bc.Protocol
                case {"Wait1", "Wait1Bpod"}
                    data.Task = "Wait1"; isWait = 1;
                case {"Wait2", "Wait2Bpod"}
                    data.Task = "Wait2"; isWait = 1;
                case {"3FPs", "ThreeFPs", "ThreeFPsMixedBpod"}
                    data.Task = "3FPs";
                case {"2FPs", "TwoFPs", "TwoFPsMixedBpodLearning"}
                    data.Task = "2FPs";
                case {"Wait1BpodLearning"}
                    data.Task = "Wait1Ephys"; isWait = 1;
                case {"Wait2BpodLearning"}
                    data.Task = "Wait2Ephys"; isWait = 1;
            end
            
            % Remove warmup trials
            if ~isWait
                idxWarmuped = bc.Stage == 1;
                bc.PressIndex = bc.PressIndex(idxWarmuped);
                bc.PressTime = bc.PressTime(idxWarmuped);
                bc.ReleaseTime = bc.ReleaseTime(idxWarmuped);
                bc.FP = bc.FP(idxWarmuped);
                bc.ToneTime = bc.ToneTime(idxWarmuped);
                bc.ReactionTime = bc.ReactionTime(idxWarmuped);
                bc.Outcome = bc.Outcome(idxWarmuped);
            end
            data.nTrial = length(bc.FP);
            data.iTrial = (1:data.nTrial)';
            data.TimeElapsed = bc.PressTime';

            % FP & RW
            if isempty(bc.FP) % Wait Period
                b = UpdateWaitB(b);
                bc.FP = b.FPs;
            end
            data.FP = bc.FP'./1000;
            data.RW = nan(data.nTrial,1);
            % Outcome
            outcome = string(bc.Outcome);
            outcome = replace(outcome,{'Correct','Premature'},{'Cor','Pre'});
            data.Outcome = outcome';
            % Reaction time & Hold time
            rt = bc.ReactionTime;
            rt(outcome=="Pre" | outcome=="Late") = NaN;
            data.RT = rt';
            
            data.HT = (bc.ReleaseTime - bc.PressTime)';
            data.RelT = data.HT - data.FP;

            % %darktry
            % idxDarkIni = [1 find(diff(idxDark)>1)+1];
            % darkNum = [diff(idxDarkIni) length(idxDarkIni(end):length(idxDark))];
            % idxDarkTrial = idxDark(idxDarkIni)-1;
            % darktry = zeros(data.nTrial,1);
            % darktry(ismember(idxTrial,idxDarkTrial)) = darkNum;
            % data.DarkTry = darktry;
            
            % add Movement time
            if ~isempty(bpodfile)
                switch class(bpodfile)
                    case 'struct'
                        sd = bpodfile;
                    otherwise
                        mustBeFile(bpodfile);
                        load(bpodfile,'SessionData');
                        sd = SessionData;
                end
                % Extract BPOD data
                trialStart = nan(1,sd.nTrials);
                medTTL = nan(1,sd.nTrials);
                mt = nan(1,sd.nTrials);
                for i=1:sd.nTrials
                    trialStart(i) = sd.TrialStartTimestamp(i);
                    % Bpod states are different between MedLick & MedOptoRec protocols
                    if isfield(sd.RawEvents.Trial{i}.States, 'WaitForPokedIn')
                        medTTL(i) = sd.RawEvents.Trial{i}.States.WaitForPokedIn(1); % if ~isnan, then mt ~isnan
                        mt(i) = diff(sd.RawEvents.Trial{i}.States.WaitForPokedIn);
                    elseif isfield(sd.RawEvents.Trial{i}.States, 'BriefReward')
                        medTTL(i) = sd.RawEvents.Trial{i}.States.BriefReward(1); % if ~isnan, then mt ~isnan
                        mt(i) = diff(sd.RawEvents.Trial{i}.States.WaitForRewardEntry);
                    else
                        error('Check Bpod MedTTL States');
                    end
                end
                % Align BPOD to MED
                t_BPOD = trialStart + medTTL;
                idxTTL = ~isnan(t_BPOD);
                t_BPOD = t_BPOD(idxTTL);
                mt = mt(idxTTL);
                idxCL = data.Outcome=="Cor" | data.Outcome=="Late";
                t_MED = data.TimeElapsed(idxCL) + data.FP(idxCL); % Tone
                
                tTTLIndexBpod2MED = findseqmatchrev(t_MED, t_BPOD, 0, 0); % each TTL(bpod) in MED timestamp
                MT_medAll = nan(data.nTrial,1);
                MT_medCL = nan(sum(idxCL),1);
                MT_medCL(tTTLIndexBpod2MED) = mt;
                MT_medAll(idxCL) = MT_medCL;
                data.MT = MT_medAll;
            else
                data.MT = nan(data.nTrial,1);
            end

            tablenames = {'Subject','Group','Experiment','Task', ...
                'Session','Date', 'iTrial','TimeElapsed',...
                'FP','RW','Outcome','HT','RT','MT','RelT'};
            t = table(...
                repelem(data.Subject, data.nTrial)',...
                repelem(NaN,          data.nTrial)',...
                repelem(NaN,          data.nTrial)',...
                repelem(data.Task,    data.nTrial)',...
                repelem(NaN,          data.nTrial)',...
                repelem(data.Date,    data.nTrial)',...
                data.iTrial, data.TimeElapsed, data.FP, data.RW, ...
                data.Outcome, data.HT, data.RT, data.MT, data.RelT,...
                'VariableNames', tablenames);

            % Generate behaviorSRT data
            idxTrial = ismember(bc.Outcome,bc.PerformanceType);
            t.iTrial(~idxTrial) = NaN;
            t.iTrial(idxTrial) = 1:sum(idxTrial);
        
            iPress = 1:size(t, 1);
            t = sortrows(t, "TimeElapsed");
            t = addvars(t, iPress', 'NewVariableNames', "iPress");
        
            data.nTrial = sum(idxTrial);
            data.nPress = length(iPress);
        
            data.TimeElapsed = t.TimeElapsed;
            data.iTrial = t.iTrial;
            data.iPress = t.iPress;
            data.Outcome = t.Outcome;
            data.FP = t.FP;
            data.RW = t.RW;
            data.RT = t.RT;
            data.HT = t.HT;
            data.MT = t.MT;
            data.RelT = t.RelT;

            close all;
            % Inherit
            obj@BehaviorSRT(data);

            % New properties
            obj.RawData = bc;
        end
    end
end